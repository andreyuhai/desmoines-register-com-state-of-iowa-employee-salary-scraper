### https://db.desmoinesregister.com/state-salaries-for-iowa Scraper

This scraper scrapes all the rows from the table at the link above, creates a database table with the name specified by you and inserts the scraped rows into the table.


Just change the database credentials in the file `main.rb` and then run:

`ruby main.rb page_from page_to`

This will scrape all the pages from `page_from` to `page_to` inclusively.


```ruby
# main.rb
dr_state_of_iowa_salary_scraper = DRStateOfIowaSalaryScraper.new(
  db_username: 'DB_USERNAME',
  db_password: 'DB_PASSWORD',
  db_host: 'DB_HOST',
  db_name: 'DB_NAME',
  table_name: 'TABLE_NAME',
  scrape_dev: 'SCRAPE_DEV'
)

page_from = ARGV[0] # Inclusive
page_from = ARGV[1] # Inclusive

dr_state_of_iowa_salary_scraper.scrape_between(page_from, page_to)
```


