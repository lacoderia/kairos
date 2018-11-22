#!/usr/bin/env ruby
require_relative "../config/environment"

period_start = ARGV[0].to_time
period_end = ARGV[1].to_time

if period_start == period_end - 1.week
  Payment.calculate_weekly_comissions period_start, period_end
elsif period_start == period_end - 1.month
  Payment.calculate_monthly_comissions period_start, period_end
else
  raise "Not valid date periods"
end