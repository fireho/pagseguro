require "net/https"
require 'net/http'
require 'httparty'
require "uri"
require "time"
require "bigdecimal"

require 'active_support/core_ext/hash/conversions'

require "pagseguro/base"
require "pagseguro/engine"
require "pagseguro/faker"
require "pagseguro/rake"
require "pagseguro/railtie"
require "pagseguro/notification"
require "pagseguro/order"
require "pagseguro/query"
require "pagseguro/action_controller"
require "pagseguro/query_transaction"
require "pagseguro/helper"
require "pagseguro/utils"
