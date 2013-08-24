module PagSeguro
  class Query

    attr_accessor :params
    attr_reader :source


    def initialize(start_data, end_data, options={})
      @params = {}
      @params[:initialDate] = start_data
      @params[:finalDate] = end_data
      @params[:page] = 1
      @params[:maxPageResults] = 100
      @params[:email] = PagSeguro.config["email"]
      @params[:token] = PagSeguro.config["authenticity_token"]

      self.params.merge!(options)


    end

    def result
      request = HTTParty.get(url_to_fetch)
      @source = Hash.from_xml(request.body)

    end



    def transactions
      self.source["transactionSearchResult"]["transactions"]["transaction"]
    end

    def url_to_fetch
      params = self.params.to_param
      uri = "https://ws.pagseguro.uol.com.br/v2/transactions?#{params}"

    end



  end
end
