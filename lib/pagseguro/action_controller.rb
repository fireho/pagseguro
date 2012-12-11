module PagSeguro
  module ActionController
    private
    def pagseguro_notification(*args)
      notification = PagSeguro::Notification.new(args)
    end
  end
end
