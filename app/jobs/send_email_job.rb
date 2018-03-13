class SendEmailJob < ActiveJob::Base
  queue_as :emails

  def perform(email_name, user, data)
    begin
      mail = KairosMailer.send(email_name.to_sym, user, data)
      mail.deliver_later
      Email.create(user: user, email_status: "sent", email_type: email_name.to_s)
    rescue Exception => e
      Email.create(user: user, email_status: e.message, email_type: email_name.to_s)
    end
  end
end
