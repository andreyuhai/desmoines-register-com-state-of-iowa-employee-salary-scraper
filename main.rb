require_relative 'lib/dr_state_of_iowa_salary_scraper'

dr_state_of_iowa_salary_scraper = DRStateOfIowaSalaryScraper.new(
  db_username: 'DB_USERNAME',
  db_password: 'DB_PASSWORD',
  db_host: 'DB_HOST',
  db_name: 'DB_NAME',
  table_name: 'TABLE_NAME',
  scrape_dev: 'SCRAPE_DEV'
)

dr_state_of_iowa_salary_scraper.scrape_between(ARGV[0], ARGV[1])