require "spec_helper"

describe PagSeguro::Query do

    let(:query) do
        PagSeguro::Query.new("2011-01-01T00:00", "2011-01-28T00:00")
    end

    subject {query}

    before(:each) do
        subject.stub :source => Hash.from_xml(File.open("#{File.expand_path("../../fixtures/", __FILE__)}/result_query_data.xml"))
    end


    it "#transactions" do
        subject.transactions.should be_kind_of(Array)
    end

    it "#url_to_fetch" do
        params = {}
        params[:initialDate] = "2011-01-01T00:00"
        params[:finalDate] = "2011-01-28T00:00"
        params[:page] = 1
        params[:maxPageResults] = 100
        params[:email] = "john@doe.com"
        params[:token] = "9CA8D46AF0C6177CB4C23D76CAF5E4B0"

        URI.decode(subject.url_to_fetch).should == "https://ws.pagseguro.uol.com.br/v2/transactions?#{URI.decode(params.to_param)}"
    end



end
