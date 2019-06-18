class ChargeFeeJob < ActiveJob::Base
  retry_on Exception, wait: 70.seconds
  queue_as :default

  def perform(user, company, order)
    begin
      payment_api = OpenpayHelper.new(company)      
      charge_fee_hash = payment_api.charge_fee(user.get_openpay_id(company), order.total_price, order.description, nil)
    rescue Exception => e
      Email.create(user: user, email_status: e.message, email_type: "Error charging fee - order #{order.openpay_id}")
      raise e
    end
  end
end
