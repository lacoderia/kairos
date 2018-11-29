#!/usr/bin/env ruby
require_relative "../config/environment"

period_start = Time.zone.now.beginning_of_month
period_end = period_start + 1.month

User.update_summaries period_start, period_end
