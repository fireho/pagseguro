module PagSeguro
    class QueryTransaction

        attr_accessor :params, :code
        attr_reader :source


        def initialize(code, options={})
            @params = {}

            @params[:email] = PagSeguro.config["email"]
            @params[:token] = PagSeguro.config["authenticity_token"]

            self.params.merge!(options)
            @code = code
        end

        def result
            request = HTTParty.get(url_to_fetch)
            @source = Hash.from_xml(request.body)['transaction']        end



        def url_to_fetch
            params = self.params.to_param
            uri = "https://ws.pagseguro.uol.com.br/v2/transactions/#{self.code}/?#{params}"
        end



    end
end

