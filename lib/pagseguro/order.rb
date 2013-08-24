# -*- coding: utf-8 -*-

module PagSeguro
  class Order

    # Map all billing attributes that will be added as form inputs.
    BILLING_MAPPING = {
      :name                  => "cliente_nome",
      :address_zipcode       => "cliente_cep",
      :address_street        => "cliente_end",
      :address_number        => "cliente_num",
      :address_complement    => "cliente_compl",
      :address_neighbourhood => "cliente_bairro",
      :address_city          => "cliente_cidade",
      :address_state         => "cliente_uf",
      :address_country       => "cliente_pais",
      :phone_area_code       => "cliente_ddd",
      :phone_number          => "cliente_tel",
      :email                 => "cliente_email"
    }

    # The list of products added to the order
    attr_accessor :products

    # The billing info that will be sent to PagSeguro.
    attr_accessor :billing

    # Define the shipping type.
    attr_accessor :shipping_type

    # Define the shipping cost.
    attr_accessor :shipping_cost

    # Define extra amount for order, positive or negative values.
    attr_accessor :extra

    # Define the Pagseguro Credentials
    attr_accessor :credentials

    attr_accessor :redirect_url

    attr_reader :code


    def initialize(order_id = nil)
      reset!
      self.id = order_id
      self.billing = {}
      self.credentials = nil
    end

    # Set the order identifier. Should be a unique
    # value to identify this order on your own application
    def id=(identifier)
      @id = identifier
    end

    # Get the order identifier
    def id
      @id
    end

    # Remove all products from this order
    def reset!
      @products = []
    end

    # Add a new product to the PagSeguro order
    # The allowed values are:
    # - weight (Optional. If float, will be multiplied by 1000g)
    # - shipping (Optional. If float, will be multiplied by 100 cents)
    # - quantity (Optional. Defaults to 1)
    # - price (Required. If float, will be multiplied by 100 cents)
    # - description (Required. Identifies the product)
    # - id (Required. Should match the product on your database)
    # - fees (Optional. If float, will be multiplied by 100 cents)
    def <<(options)
      options = {
        :weight => nil,
        :shipping => nil,
        :fees => nil,
        :quantity => 1
      }.merge(options)

      # convert shipping to cents
      options[:shipping] = convert_unit(options[:shipping], 100)

      # convert fees to cents
      options[:fees] = convert_unit(options[:fees], 100)

      # convert price to cents
      options[:price] = convert_unit(options[:price], 100)

      # convert weight to grammes
      options[:weight] = convert_unit(options[:weight], 1000)

      products.push(options)
    end

    def add(options)
      self << options
    end

    def send
      uri = URI.parse('https://ws.pagseguro.uol.com.br/v2/checkout/')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      request = Net::HTTP::Post.new(uri.path)
      request.form_data = self.data_to_send
      response = http.start {|r| r.request request }

      hash = Hash.from_xml(response.body)

      if hash["checkout"].nil?
        raise RuntimeError, hash.inspect
      else
        @code = hash["checkout"]["code"]
      end
    end

    def link_to_pay
      "https://pagseguro.uol.com.br/v2/checkout/payment.html?code=#{self.code}"
    end

    def data_to_send
      ## https://pagseguro.uol.com.br/v2/guia-de-integracao/api-de-pagamentos.html
      data = {}

      # Products
      self.products.each_with_index do |product, i|;  i += 1
        data["itemId#{i}"]           = product[:id]
        data["itemQuantity#{i}"]     = product[:quantity]
        data["itemDescription#{i}"]  = Utils.to_iso8859(product[:description])
        data["itemAmount#{i}"]       = revert_unit(product[:price])
        data["itemShippingCost#{i}"] = revert_unit(product[:shipping]) if product[:shipping]
      end

      # Buyer
      data["senderName"]     = Utils.to_iso8859(self.billing[:name])
      data["senderEmail"]    = self.billing[:email]
      data["senderPhone"]    = self.billing[:phone_number]
      data["senderAreaCode"] = self.billing[:phone_area_code]

      # Shipping
      data["shippingType"]   = shipping_type_revert(self.shipping_type)
      data["shippingCost"]   = revert_unit(shipping_cost) if shipping_cost

      # Address
      data["shippingAddressCity"]       = Utils.to_iso8859(self.billing[:address_city])
      data["shippingAddressState"]      = self.billing[:address_state]
      data["shippingAddressDistrict"]   = Utils.to_iso8859(self.billing[:address_neighbourhood])
      data["shippingAddressCountry"]    = "BRA"  ## No momento, apenas o valor BRA é permitido
      data["shippingAddressStreet"]     = Utils.to_iso8859(self.billing[:address_street])
      data["shippingAddressNumber"]     = self.billing[:address_number]
      data["shippingAddressComplement"] = Utils.to_iso8859(self.billing[:address_complement])
      data["shippingAddressPostalCode"] = self.billing[:address_zipcode]

      # Other
      data["currency"]  = "BRL"
      data["reference"] = self.id
      data["extraAmount"] = revert_unit(convert_unit(@extra, 100))

      if @credentials.nil?
        data["token"] = PagSeguro.config["authenticity_token"]
        data["email"] = PagSeguro.config["email"]
      else
        data["token"] = @credentials[:token]
        data["email"] = @credentials[:email]
      end

      data["redirectUrl"] = @redirect_url
      return data
    end


    private


    def convert_unit(number, unit)
      number = (BigDecimal("#{number}") * unit).to_i unless number.nil? || number.kind_of?(Integer)
      number
    end

    def revert_unit(number)
      item_price = number.to_f
      item_amount = item_price / 100
      "%.2f" % item_amount
    end

    def shipping_type_revert(type)
      case type
      when "EN", :pac   then 1
      when "SD", :sedex then 2
      else 3
      end
    end

  end
end
