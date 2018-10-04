class Summary 
  include ActiveModel::Model

  attr_accessor :current_month, :previous_month, :ranks
  # current_month: {name, omein_vg, omein_vp, prana_vg, prana_vp}
  # previous_month: {name, omein_vg, omein_vp, prana_vg, prana_vp}
  # ranks: {previous, max}

  def self.get_for_user user
    summary = {current_month: {}, previous_month: {}, ranks: {}}
           
    #current month
    summary[:current_month][:name] = "Septiembre"
    summary[:current_month][:omein_vg] = 1000
    summary[:current_month][:omein_vp] = 100
    summary[:current_month][:prana_vg] = 1000
    summary[:current_month][:prana_vp] = 100 
    
    #previous month
    summary[:previous_month][:name] = "Agosto"
    summary[:previous_month][:omein_vg] = 500
    summary[:previous_month][:omein_vp] = 100
    summary[:previous_month][:prana_vg] = 400
    summary[:previous_month][:prana_vp] = 100 

    #ranks
    summary[:ranks][:previous] = "Empresario"
    summary[:ranks][:max] = "1k"

    return summary    
  end
  
end

