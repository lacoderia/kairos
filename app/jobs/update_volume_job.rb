class UpdateVolumeJob < ActiveJob::Base
  queue_as :default

  def perform(user, data)
    begin
      user.recursive_update_volume_with_uplines(data[:period_start].to_s.in_time_zone, data[:period_end].to_s.in_time_zone, data[:company])
    rescue Exception => e
      Email.create(user: user, email_status: e.message, email_type: "error_updating_volume_with_uplines")
    end
  end
end
