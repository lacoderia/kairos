class AsynchSummaryJob < ActiveJob::Base
  queue_as :default

  def perform(user, data)
    begin
      result = Summary.create_summary user, data[:period_start], data[:period_end]
      SendEmailJob.perform_later("send_summary", user, result) 
    rescue Exception => e
      Email.create(user: user, email_status: e.message, email_type: "error_calculating_summary")
    end
  end
end
