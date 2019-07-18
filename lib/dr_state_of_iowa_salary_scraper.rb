require 'mechanize'
require 'pry'
require_relative '../lib/database'

class DRStateOfIowaSalaryScraper
  attr_accessor :agent, :db, :table_name, :scrape_dev

  def initialize(**params)
    db_username = params.fetch(:db_username)
    db_password = params.fetch(:db_password)
    db_host = params.fetch(:db_host)
    db_name = params.fetch(:db_name)
    @scrape_dev = params.fetch(:scrape_dev)
    @table_name = params.fetch(:table_name)

    @db = Database.new(db_username, db_password, db_host, db_name)
    create_table(@table_name)
    @agent = Mechanize.new
  end

  def scrape
    response = @agent.get 'https://db.desmoinesregister.com/state-salaries-for-iowa'
    parsed_response_body = Nokogiri::HTML(response.body)

    page_count = get_page_count(parsed_response_body)

    (1..page_count).each do |page_num|
      puts "[#{page_num}]\t--------------------------"
      url = "https://db.desmoinesregister.com/state-salaries-for-iowa/page=#{page_num}&ordercol=col11&orderdir=desc"

      response = @agent.get url
      parsed_response_body = Nokogiri::HTML(response.body)

      rows = parsed_response_body.xpath("//table[@class='responsive full']/tbody/tr")

      rows.each_with_index do |row, index|

        cells = row.xpath('td')

        employee_name = cells[0].text.strip
        department = cells[1].text.strip
        position = cells[2].text.strip
        county = cells[3].text.strip
        sex = cells[4].text.strip
        july_salary = cells[5].text.match(/\d*,*\d+\.*\d*/).nil? ? 'NULL' : cells[5].text.match(/\d*,*\d+\.*\d*/).to_s.gsub(',', '').to_f
        travel = cells[6].text.match(/\d*,*\d+\.*\d*/).to_s.gsub(',', '').to_f
        fy_salary = cells[7].text.match(/\d*,*\d+\.*\d*/).to_s.gsub(',', '').to_f
        fy = cells[8].text.to_i

        puts "\t\t[#{index}]\t#{employee_name}\t#{department}\t#{july_salary}\t#{travel}\t#{fy_salary}\t#{fy}"
        params = {
          table_name: @table_name,
          query: {
            employee_name: employee_name,
            department: department,
            position: position,
            county: county,
            sex: sex,
            july_salary: july_salary,
            travel: travel,
            fy_salary: fy_salary,
            fy: fy,
            created_by: @scrape_dev
          }
        }
        @db.insert_into_table(params)
      end
    end
  end

  def get_page_count(parsed_response_body)
    parsed_response_body.xpath("(//ul[@class='pagination'])[1]/li[not(@class='arrow')][last()]").first.text.to_i
  end

  def create_table(table_name)
    params = {
      table_name: table_name,
      columns: {
        id: 'INT AUTO_INCREMENT',
        employee_name: 'VARCHAR(50)',
        department: 'VARCHAR(100)',
        position: 'VARCHAR(100)',
        county: 'VARCHAR(100)',
        sex: 'CHAR(1)',
        july_salary: 'DOUBLE',
        travel: 'DOUBLE',
        fy_salary: 'DOUBLE',
        fy: 'INT',
        created_at: 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
        updated_at: 'TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
        created_by: 'VARCHAR(50)'
      },
      primary_key: 'id',
      unique: {
        all_columns: %w[employee_name department position county sex july_salary travel fy_salary fy]
      }
    }
    @db.create_table(params)
  end
end
