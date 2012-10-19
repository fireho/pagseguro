require "spec_helper"
require 'uri'




describe PagSeguro::Order do
  before do
    @order = PagSeguro::Order.new
    @product = {:price => 9.90, :description => "Ruby 1.9 PDF", :id => 1}
    @product2 = {:price => 9.90, :description => "Ruby 1.9 PDF", :id => 1, :shipping => 4.00}
    @product3 = {:price => 9.90, :description => "hello buddy", :id => 1}

    @order.billing = {
      :name                  => "John Doe",
      :email                 => "john@doe.com",
      :address_zipcode       => "01234-567",
      :address_street        => "Rua Orobo",
      :address_number        => "72",
      :address_complement    => "Casa do fundo",
      :address_neighbourhood => "Tenorio",
      :address_city          => "Pantano Grande",
      :address_state         => "AC",
      :address_country       => "Brasil",
      :phone_area_code       => 22,
      :phone_number          => "56273440"
    }
    @order.shipping_type = "EN"

    PagSeguro.stub :config => {"authenticity_token" => "26C19EE2DF014CAD93F63657CDD9A3EX", "email" => "nandosousafr@gmail.com"}

    @order.stub :code => "26C19EE2DF014CAD91E63657BDD9A3F4"

  end





  it "should set order id when instantiating object" do
    @order = PagSeguro::Order.new("ABCDEF")
    @order.id.should == "ABCDEF"
  end

  it "should set order id throught setter" do
    @order.id = "ABCDEF"
    @order.id.should == "ABCDEF"
  end

  it "should reset products" do
    @order.products += [1,2,3]
    @order.products.should have(3).items
    @order.reset!
    @order.products.should be_empty
  end

  it "should alias add method" do
    @order.should_receive(:<<).with(:id => 1)
    @order.add :id => 1
  end

  it "should add product with default settings" do
    @order << @product

    @order.products.should have(1).item

    p = @order.products.first
    p[:price].should == 990
    p[:description].should == "Ruby 1.9 PDF"
    p[:id].should == 1
    p[:quantity].should == 1
    p[:weight].should be_nil
    p[:fees].should be_nil
    p[:shipping].should be_nil
  end

  it "should add product with custom settings" do
    @order << @product.merge(:quantity => 3, :shipping => 3.50, :weight => 100, :fees => 1.50)
    @order.products.should have(1).item

    p = @order.products.first
    p[:price].should == 990
    p[:description].should == "Ruby 1.9 PDF"
    p[:id].should == 1
    p[:quantity].should == 3
    p[:weight].should == 100
    p[:shipping].should == 350
    p[:fees].should == 150
  end

  it "should convert amounts to cents" do
    @order << @product.merge(:price => 9.99, :shipping => 3.67)

    p = @order.products.first
    p[:price].should == 999
    p[:shipping].should == 367
  end

  specify "bug fix: should convert 1.15 correctly" do
    @order << @product.merge(:price => 1.15)

    p = @order.products.first
    p[:price].should == 115
  end

  it "should convert big decimal to cents" do
    @product.merge!(:price => BigDecimal.new("199.00"))
    @order << @product

    p = @order.products.first
    p[:price].should == 19900
  end

  it "should convert weight to grammes" do
    @order << @product.merge(:weight => 1.3)
    @order.products.first[:weight].should == 1300
  end

  it "should respond to billing attribute" do
    @order.should respond_to(:billing)
  end

  it "should initialize billing attribute" do
    @order.billing.should be_instance_of(Hash)
  end

  it "should revert big decimal to float" do
    @order << @product
    @order.data_to_send["itemAmount1"].should == "9.90"


  end


  it "should eq to shippingType to post" do
    @order << @product
    @order.data_to_send["shippingType"].should == 1
  end




  it "should return valid link" do
    @order << @product
    @order << @product2
    @order << @product3



    link = @order.link_to_pay

    link.should == "https://pagseguro.uol.com.br/v2/checkout/payment.html?code=#{@order.code}"

  end

  it "should customize token and email inline" do
    PagSeguro.stub :config => {"authenticity_token" => nil, "email" => nil}


    @order.pagseguro_token = "26C19EE2DF014CAD91E63657BDD9A3F4"
    @order.pagseguro_email = "nandosousafr@gmail.com"

    @order.data_to_send["token"].should == "26C19EE2DF014CAD91E63657BDD9A3F4"
    @order.data_to_send["email"].should == "nandosousafr@gmail.com"

  end



end
