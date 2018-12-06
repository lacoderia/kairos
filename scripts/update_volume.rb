#!/usr/bin/env ruby
require_relative "../config/environment"

logger = Logger.new('/home/deploy/kairos/log/update_summaries.log', 5, 1024000)

begin
  period_start = Time.zone.now.beginning_of_month
  period_end = period_start + 1.month
  User.update_summaries period_start, period_end

  if Time.zone.now.day <= 10
    period_start = period_start - 1.month
    period_end = period_start + 1.month
    User.update_summaries period_start, period_end
  end

  logger.info("Successfully completed")  
rescue Exception => e
  logger.error("Error - #{e.message}")
end
