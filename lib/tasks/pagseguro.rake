namespace :pagseguro do
  desc "Send notification to the URL specified in config/pagseguro.yml"
  task :notify => :environment do
    PagSeguro::Rake.run
  end
end
