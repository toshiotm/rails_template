require 'bundler'

@app_name = app_name

run 'rm README.rdoc'

run 'gibo OSX Ruby Rails SASS > .gitignore' rescue nil
gsub_file '.gitignore', /config\/initializers\/secret_token.rb$/, ''
gsub_file '.gitignore', /config\/secret.yml/, ''

append_file 'Gemfile', <<-CODE

gem 'libv8'
gem 'therubyracer', platforms: :ruby
gem 'bcrypt', '~> 3.1.7'
gem 'rails-i18n'
gem 'jquery-turbolinks'
gem 'sprockets-rails', '2.3.3'

gem 'slim-rails'

gem 'quiet_assets'

gem 'rails-flog'

gem 'migration_comments'

group :development, :test do
    gem 'pry-rails'
    gem 'pry-coolline'
    gem 'pry-byebug'
    gem 'rb-readline'
    gem 'hirb'
    gem 'hirb-unicode'
    gem 'awesome_print'
end

group :test do
    gem "minitest-rails-capybara"
    gem 'timecop'
    gem 'faker'
end

CODE

if yes?("Do use Mysql?")
    append_file 'Gemfile', "gem 'mysql2'" 
elsif yes?("Postgresql?")
    append_file 'Gemfile', "gem 'pg'" 
end



Bundler.with_clean_env do
    run 'bundle install --path vendor/bundle --jobs=4'
end


application do
    %q{
        config.time_zone = 'Tokyo'
        config.active_record.default_timezone = :local
        
        I18n.enforce_available_locales = true
        config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb, yml}').to_s]
        config.i18n.default_local = :ja
        
        config.generators do |g|
            g.template_engine :slim
            g.view_specs false
            g.controller_specs false
            g.routing_specs false
            g.helper_specs false
            g.request_specs false
            g.assets false
            g.helper false
        end
        
    }
end

insert_into_file 'test/test_helper.rb',%(
    require "capybara/rails"

    class ActionDispatch::IntegrationTest
        include Capybara::DSL
    end
), before: 'class ActiveSupport::TestCase'



# 日本語Locale
run 'wget https://raw.github.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml -P config/locales/'

run 'rm -rf app/assets/javascripts/application.js'
run 'wget https://raw.github.com/toshiotm/rails_template/master/app/assets/javascripts/application.js -P app/assets/javascripts/'


# DB
run 'rm -rf config/database.yml'
if yes?('Use MySQL?([yes] else PostgreSQL)')
  run 'wget https://raw.github.com/toshiotm/rails_template/master/config/mysql/database.yml -P config/'
else
  run 'wget https://raw.github.com/toshiotm/rails_template/master/config/postgresql/database.yml -P config/'
  run "createuser #{@app_name} -s"
end

gsub_file 'config/database.yml', /APPNAME/, @app_name
Bundler.with_clean_env do
  run 'bundle exec rake RAILS_ENV=development db:create'
  run 'bundle exec rake RAILS_ENV=test db:create'
end


git :init
git :add => '.'
git :commit => "-a -m 'first commit'"

