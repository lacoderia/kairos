FactoryBot.define do

  #user_id, period_start, period_end, current_omein_vg, current_omein_vp, current_prana_vg, current_omein_vp
  #previous_omein_vg, previous_omein_vp, previous_prana_vg, previous_prana_vp, previous_rank
  factory :summary, class: Summary do
    
    period_start Time.zone.now.beginning_of_month
    period_end Time.zone.now.beginning_of_month + 1.month
    current_omein_vg 800
    current_omein_vp 100
    current_prana_vg 800
    current_prana_vp 100
    previous_omein_vg 1000
    previous_omein_vp 100
    previous_prana_vg 1100
    previous_prana_vp 100
    previous_rank "1K"
    association :user, factory: :user

  end

end
