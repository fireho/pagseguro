# encoding: utf-8
require "spec_helper"

describe PagSeguro::Notification do

  let(:fixture) { YAML.load_file(File.dirname(__FILE__) + "/../fixtures/notification.yml") }

  before(:each) do
    @notification = PagSeguro::Notification.new("9E884542-81B3-4419-9A75-BCC6FB495EF1")
    @notification.stub :source => fixture.to_xml(:root => :transaction)

    PagSeguro.stub :config => {:email => "hommer@gmail.com", :authenticity_token => "default"}

  end



  subject { @notification }

  it "can customize credentials" do
    @notification = PagSeguro::Notification.new("111", "nandosousafr@gmail.com", "26C19EE2DF014CAD93F63657CDD9A3EX")


    subject.credentials[:email].should == "nandosousafr@gmail.com"
    subject.credentials[:token].should == "26C19EE2DF014CAD93F63657CDD9A3EX"

  end

  it { subject.date.should == fixture["date"].to_datetime }
  it { subject.code.should == fixture["code"] }
  it { subject.reference.should == fixture["reference"] }
  it { subject.type.should == fixture["type"] }

  it { subject.status(:name).should == "paga" }
  it { subject.status.should == fixture["status"] }

  it { subject.payment_method(:name).should == "cartão de crédito" }
  it { subject.payment_method.should == 1 }


  it "group amount" do
    subject.amount_group.should be_kind_of(Hash)

    subject.amount_group[:grossAmount].should == fixture["grossAmount"]
    subject.amount_group[:discountAmount].should == fixture["discountAmount"]
    subject.amount_group[:feeAmount].should == fixture["feeAmount"]
    subject.amount_group[:extraAmount].should == fixture["extraAmount"]

  end

  it { subject.should have(2).items }
  it { subject.sender["name"].should == fixture["sender"]["name"] }
  it { subject.shipping["address"]["number"].should == fixture["shipping"]["address"]["number"] }


  it "writing w/ blocks" do
    @notification = PagSeguro::Notification.new do |p|
      p.credentials = {:token => "custom_token", :email => "c@gmail.com"}
      p.notification_code = "custom_notification_code"
    end

    @notification.notification_code.should == "custom_notification_code"
    @notification.credentials.should == {:token => "custom_token", :email => "c@gmail.com"}
  end



end
