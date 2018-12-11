ActiveAdmin.register User, as: "Distribuidores" do

  actions :all, :except => [:show, :destroy]

  permit_params :first_name, :last_name, :external_id, :sponsor_external_id, :placement_external_id, :phone, :active, :email, :iuvare_id, :phone_alt, :phone, :created_at, :password, shipping_addresses_attributes: [:address, :city, :state, :country, :zip]
  
  filter :first_name, as: :string, label: "Nombre"
  filter :last_name, as: :string, label: "Apellido"
  filter :email, as: :string
  filter :external_id, label: "ID Omein"
  filter :created_at, label: "Creación"
  filter :sponsor_external_id, label: "ID Patrocinio"  
  filter :placement_external_id, label: "ID Colocación"  

  controller do

    def create
      
      sponsor = User.find_by_external_id(params[:user][:sponsor_external_id])
      placement = User.find_by_external_id(params[:user][:placement_external_id])

      if sponsor and placement
        super
      else
        @user = User.new(permitted_params[:user])
        @user.errors.add(:incorrect_uplines, "No se encontró upline con ese ID depatrocinio o colocación.")
        flash[:error] = 'No se encontró upline con ese ID de patrocinio o colocación.'
        redirect_to new_admin_distribuidore_path
      end
    end

    def update
      if not current_admin_user.role? :niumedia
        if params[:instructor][:admin_user_attributes][:password].blank?
          params[:instructor][:admin_user_attributes].delete("password")
          params[:instructor][:admin_user_attributes].delete("password_confirmation")
        end
      end
      super
    end

    def update 
      
      sponsor = User.find_by_external_id(params[:user][:sponsor_external_id])
      placement = User.find_by_external_id(params[:user][:placement_external_id])

      if sponsor and placement
        if params[:user][:password].blank?
          params[:user].delete("password")
        end
        super
      else
        @user = User.new(permitted_params[:user])
        @user.errors.add(:incorrect_uplines, "No se encontró upline con ese ID depatrocinio o colocación.")
        flash[:error] = 'No se encontró upline con ese ID de patrocinio o colocación.'
        redirect_to edit_admin_distribuidore_path
      end
    end

  end

  config.sort_order = 'created_at_desc'

  index title: "Distribuidores" do
    column "Nombre", :first_name
    column "Apellido", :last_name
    column "Email", :email
    column "ID Omein", :external_id
    column "Creación", :created_at     
    column "ID Patrocinio", :sponsor_external_id
    column "ID Colocacion", :placement_external_id
    column "" do |user|
      link_to "Order", "#{new_admin_ordene_path}?user_id=#{user.id}"
    end
    
    actions defaults: true
  end

  form do |f|
    #Default values
    f.object.created_at = DateTime.now unless f.object.created_at
    f.object.external_id = User.with_max_id.external_id + 1
    
    f.semantic_errors *f.object.errors.keys

    f.inputs "Información de distribuidor" do
      f.input :first_name, label: "Nombre"
      f.input :last_name, label: "Apellido"
      f.input :email, label: "Email"
      f.input :external_id, label: "ID Omein"
      f.input :created_at, label: "Creación", as: :datepicker 
      f.input :sponsor_external_id, label: "ID Patrocinio"
      f.input :placement_external_id, label: "ID Colocacion"
      f.input :phone, label: "Teléfono"
      f.input :phone_alt, label: "Celular"
      f.input :password, label: "Password"
      f.inputs "Direcciones" do
          f.has_many :shipping_addresses, allow_destroy: true, new_record: true do |a|
            a.input :address, label: "Dirección"
            a.input :city, label: "Ciudad"
            a.input :state, label: "Estado"
            a.input :country, label: "País", collection: ["México", "España", "Colombia", "Otro"], 
              as: :select, selected: "México", include_blank: false
            a.input :zip, label: "Código Postal"
        end
      end
    end
    f.actions
  end

end
