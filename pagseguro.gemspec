# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pagseguro/version"

Gem::Specification.new do |s|
  s.name        = "pagseguro"
  s.version     = PagSeguro::Version::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nando Vieira"]
  s.email       = ["fnando.vieira@gmail.com"]
  s.homepage    = "http://rubygems.org/gems/pagseguro"
  s.summary     = "The official PagSeguro library"
  s.description = s.summary
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]


  s.add_dependency "httparty"                 , "~> 0.11.0"
  s.add_development_dependency "rails"        , "~> 4.0"
  s.add_development_dependency "faker"        , "~> 1.2"
  s.add_development_dependency "rake"         , "~> 0.9"
  s.add_development_dependency "fakeweb"      , "~> 1.3"
  s.add_development_dependency "fabrication"  , "~> 2.9"
  s.add_development_dependency "rspec-rails"  , "~> 2.7"
  s.add_development_dependency "nokogiri"     , "~> 1.6"
  s.add_development_dependency "sqlite3"      , "~> 1.3"
end
