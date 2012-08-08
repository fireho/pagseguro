module PagSeguro
  class Order
    require 'uri'
    require 'net/http'
    require 'active_support/core_ext/hash/conversions'
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
    # Can be EN (PAC) or SD (Sedex)
    attr_accessor :shipping_type

    def initialize(order_id = nil)
      reset!
      self.id = order_id
      self.billing = {}
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
      params = URI.encode_www_form(self.data_to_send)

      uri = URI.parse('https://ws.pagseguro.uol.com.br/v2/checkout/')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true 
    

      request = Net::HTTP::Post.new(uri.path)
      request.form_data = self.data_to_send
      response = http.start {|r| r.request request }
      response.body
    
      
      hash = Hash.from_xml(response.body)
      
      
      @@code = hash["checkout"]["code"]

    end

    
    def link_to_pay
      code = @@code
      link = "https://pagseguro.uol.com.br/v2/checkout/payment.html?code=#{code}"
    end
    
  


    def data_to_send
      data = {}

      self.products.each_with_index do |product, i|
        i += 1


        item_price = BigDecimal(product[:price]).to_f
        item_amount = item_price / 100
        
        
        data["itemId#{i}"] = product[:id]
        data["itemDescription#{i}"] = product[:description]
        data["itemAmount#{i}"] = "%.2f" % item_amount.to_f
        data["itemShippingCost#{i}"] = product[:shipping]  if product[:shipping]
         data["itemQuantity#{i}"] = product[:quantity]
      end
      



      data["shippingType"] = shipping_type_revert(self.shipping_type)
      data["senderName"] = self.billing[:name]
      data["senderAreaCode"] = self.billing[:phone_area_code]
      data["senderPhone"] = self.billing[:phone_number]
      data["senderEmail"] = self.billing[:email]

      data["shippingAddressStreet"] = self.billing[:address_street]
      data["shippingAddressNumber"] = self.billing[:address_number]
      data["shippingAddressComplement"] = self.billing[:address_complement]
      data["shippingAddressDistrict"] = self.billing[:address_neighbourhood]
      data["shippingAddressPostalCode"] = self.billing[:address_zipcode]
      data["shippingAddressCity"] = self.billing[:address_city]
      data["shippingAddressState"] = self.billing[:address_state]
      data["shippingAddressCountry"] = "BRA"  ## No momento, apenas o valor BRA é permitido
      ## https://pagseguro.uol.com.br/v2/guia-de-integracao/api-de-pagamentos.html

      data["currency"] = "BRL"
      data["reference"] = self.id

      data["token"] = PagSeguro.config["authenticity_token"]
      data["email"] = PagSeguro.config["email"]

      data

    end

    

    private
    def convert_unit(number, unit)
      number = (BigDecimal("#{number}") * unit).to_i unless number.nil? || number.kind_of?(Integer)
      number
    end

    def shipping_type_revert(type)
      case type
      when "EN" then 1
      when "SD" then 2
      when "FT" then 3
      end
    end



  end
end
