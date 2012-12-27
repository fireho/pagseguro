require "spec_helper"

describe PagSeguro::QueryTransaction do
    let(:query) { PagSeguro::QueryTransaction.new("9E884542-81B3-4419-9A75-BCC6FB495EF1") }

    subject { query }

    before(:each) do
        subject.stub :source => Hash.from_xml(File.open("#{File.expand_path("../../fixtures/", __FILE__)}/result_query_transaction_data.xml"))
    end

    it "#result" do
        subject.source['transaction']['code'].should == "9E884542-81B3-4419-9A75-BCC6FB495EF1"
    end

end
