ActiveAdmin.register Summary, as: "Volumen Usuario" do 

  actions :all, :except => [:new, :edit, :destroy, :show]

  filter :period_start, as: :date_range, label: "Periodo"
  filter :user, collection: -> { User.all.map { |user| [user.external_id, user.id] }.sort } 
  filter :omein_vp
  filter :omein_vg
  filter :prana_vp
  filter :omein_vg

  index title: "Volume de usuarios" do
    column "Futura ID" do |summary|
      summary.user.external_id
    end

    column "Nombre" do |summary|
      "#{summary.user.first_name} #{summary.user.last_name}"
    end

    column "Omein VP", :omein_vp
    column "Omein VG", :omein_vg
    column "Prana VP", :prana_vp
    column "Prana VG", :prana_vg
    column "Periodo", :period_start    
    
  end



end
