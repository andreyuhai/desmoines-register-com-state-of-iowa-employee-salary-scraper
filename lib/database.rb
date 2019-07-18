require 'mysql2'

class Database
  attr_reader :client

  def initialize(db_username, db_password, db_host, db_name)
    @client = Mysql2::Client.new(username: db_username, password: db_password, database: db_name, host: db_host)
  end

  def create_table(**params)
    table_name = params.fetch(:table_name)
    columns = []
    params.fetch(:columns).each {|key, value| columns << "#{key} #{value}"}
    primary_key = params[:primary_key]
    foreign_keys = params[:foreign_keys]
    unique = params[:unique]

    statement = "CREATE TABLE IF NOT EXISTS #{table_name} ( #{columns.join(',')}"
    statement += ", PRIMARY KEY (#{primary_key})" unless primary_key.nil?
    foreign_keys&.each do |key_name, hash|
      foreign_key_statement = []
      foreign_key_statement << "FOREIGN KEY #{key_name}(#{hash.fetch(:foreign_key_column)}) REFERENCES #{hash.fetch(:referenced_table)} (#{hash.fetch(:referenced_column)})"
      statement += ", #{foreign_key_statement.join(',')}"
    end

    unique&.each do |key, value|
      unique_key_statement = []
      unique_key_statement << "UNIQUE KEY #{key} (#{value.join(',')})"
      statement += ", #{unique_key_statement.join(',')}"
    end


    statement += ') CHARACTER SET UTF8'
    @client.query statement
  end

  def insert_into_table(**params)
    table_name = params.fetch(:table_name)
    query_hash = params.fetch(:query)
    column_names = query_hash.keys.join(',')
    values = query_hash.values.map do |value|
      value = escape_single_quotes(value).strip if value.instance_of? String
      value = if value == 'NULL'
                value
              else
                "'#{value}'"
              end
    end.join(',')

    statement = <<-END_SQL.gsub(/\s+/, ' ').strip
    INSERT INTO #{table_name}(#{column_names})
    VALUES(#{values})
    END_SQL

    @client.query statement
  end

  # @param [Hash] params
  # @return [Boolean] returns either false or true depending on whether the row exists in the specified table.
  def exists?(**params)
    table_name = params.fetch(:table_name)
    where_statement = params.fetch(:where)

    results = select_from_table(table_name: table_name, where: where_statement)
    !results.count.zero?
  end

  def select_from_table(**params)
    table_name = params.fetch(:table_name)
    column_names = params[:select].nil? ? '*' : params[:select]
    order_by = params[:order_by].nil? ? '' : params[:order_by]
    join = params[:join].nil? ? '' : params[:join]
    where_statement = if params[:where].nil?
                        ''
                      else
                        where_array = []
                        params[:where].each do |key, hash|
                          where_array << "#{key} #{hash.fetch(:operator)} '#{escape_single_quotes(hash.fetch(:value))}'"
                        end
                        where_array.join(" and ")
                      end

    statement = <<-END_SQL.gsub(/\s+/, ' ').strip
    SELECT #{column_names} FROM #{table_name}
    END_SQL

    statement += " #{join.fetch(:type).upcase} #{join.fetch(:table)} ON #{join.fetch(:on)}" unless join.empty?
    statement += " WHERE #{where_statement}" unless where_statement.empty?
    statement += " ORDER BY #{order_by}" unless order_by.empty?

    @client.query(statement, symbolize_keys: true)
  end

  # @param [String] string - String to escape single quotes from
  # @return [String] single quotes escaped string
  def escape_single_quotes(string)
    string.gsub("'", "\\\\'")
  end
end