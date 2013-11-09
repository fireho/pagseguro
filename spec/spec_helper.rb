# This file is copied to spec/ when you run 'rails generate rspec:install'
# require 'spork'
ENV["RAILS_ENV"] ||= 'test'

# Spork.prefork do

require File.expand_path("../dummy/config/environment", __FILE__)

require 'rspec/rails'
require 'rspec/autorun'
require 'faker'
require 'fabrication'
require 'fabrication/syntax/make'

require "pagseguro"
require "fakeweb"
# require "support/config/boot"
# require "support/matcher"
# require "support/faker"

FakeWeb.allow_net_connect = true

# is valid url
def valid?(url)
  uri = URI.parse(url)
  uri.kind_of?(URI::HTTP)
rescue URI::InvalidURIError
  false
end


# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Pagseguro::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

Capybara.javascript_driver = :poltergeist
  #Capybara.server_port = 9999
WebMock.disable_net_connect!(:allow_localhost => true)

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
# ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)
  # geo_fabricators = Pathname.new(Gem.loaded_specs['geopolitical'].gem_dir + "/spec/fabricators")
  # Fabrication.configure do |c|
  #   c.path_prefix = Rails.root.join("../../")
  #   c.fabricator_path << geo_fabricators.relative_path_from(Pathname.new(c.path_prefix))
  #   p c.fabricator_path
  # end

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  # config.include Capybara::DSL

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end
#end
