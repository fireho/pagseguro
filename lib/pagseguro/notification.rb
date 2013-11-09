# encoding: utf-8
module PagSeguro
  class Notification

    STATUS = {
      1 => 'aguardando pagamento',
      2 => 'em análise',
      3 => 'paga',
      4 => 'disponível',
      5 => 'em disputa',
      6 => 'devolvida',
      7 => 'cancelada'
    }

    PAYMENT_METHOD = {
      1 => 'cartão de crédito',
      2 => 'boleto',
      3 => 'débido online',
      4 => 'saldo pagseguro',
      5 => 'oi paggo'
    }

    # define xml source string
    attr_accessor :source

    # usefull to customize credentials
    attr_accessor :credentials

    attr_accessor :notification_code

    def initialize(*args, &blocks)
      @notification_code = args.first
      if args[1] && args[2]
        @credentials = { :email => args.second, :token => args.third }
      else
        @credentials = {
          :email => PagSeguro.config["email"],
          :token => PagSeguro.config["authenticity_token"] }
      end

      yield self if block_given?

      result

    end

    def data
      Hash.from_xml(self.source)["transaction"]
    end


    def result
      request = HTTParty.get(url_to_fetch)
      @source = request.body
    end


    def date
      fetch('date').to_datetime
    end

    def code
      fetch('code')
    end

    def type
     fetch('type').to_i
    end

    def status(name=nil)
      id = fetch('status').to_i
      name.nil? ? id : STATUS[id]
    end


    #todo get code of payment => MasterCard
    def payment_method(name=nil)
      id = fetch('paymentMethod')["type"]
      name.nil? ? id : PAYMENT_METHOD[id]
    end


    def reference
      fetch('reference')
    end

    def amount_group(key=nil)
      group = {}
      group[:grossAmount] = fetch('grossAmount').to_f
      group[:discountAmount] = fetch('discountAmount').to_f
      group[:feeAmount] = fetch('feeAmount').to_f
      group[:netAmount] = fetch('netAmount').to_f
      group[:extraAmount] = fetch('extraAmount').to_f

      key ? group[key] : group
    end

    def items
      fetch 'items'
    end

    def sender
      fetch 'sender'
    end

    def shipping
      fetch 'shipping'
    end


    private

    def fetch(node)
      self.data[node]
    end

    def url_to_fetch
      uri = "https://ws.pagseguro.uol.com.br/v2/transactions/notifications/#{self.notification_code}?#{self.credentials.to_param}"
    end

  end
end
