ENV["RAILS_ENV"] = "test"
require "rails"
require "fakeweb"
require "pagseguro"
require "support/config/boot"
require "rspec/rails"
require "nokogiri"
require "support/matcher"

FakeWeb.allow_net_connect = true

# is valid url
def valid?(url)
  uri = URI.parse(url)
  uri.kind_of?(URI::HTTP)
rescue URI::InvalidURIError
  false
end