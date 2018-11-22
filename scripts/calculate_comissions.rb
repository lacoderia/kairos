#!/usr/bin/env ruby
require_relative "../config/environment"

period_start = ARGV[0].to_s.in_time_zone
period_end = ARGV[1].to_s.in_time_zone

if period_start == period_end - 1.week
  Payment.calculate_weekly period_start, period_end
elsif period_start == period_end - 1.month
  Payment.calculate_monthly period_start, period_end
else
  raise "Not valid date periods"
end
