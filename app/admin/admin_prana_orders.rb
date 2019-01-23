ActiveAdmin.register Order, as: "Prana Ordenes" do

  actions :all, :except => [:show]

  filter :created_at, as: :date_range, label: "Fecha de creación"
  filter :order_number, label: "Número de orden"
  filter :users, collection: -> { User.all.map { |user| [user.external_id, user.id] }.sort }

  permit_params :description, :order_number, :user_ids, :created_at, item_ids: [], items_attributes: [:id]

  controller do

    def scoped_collection
      Order.joins(:items).where("company = ?", PranaCompPlan::COMPANY_PRANA).distinct
    end

    def create
      params[:order][:item_ids] = []
      items = params[:order][:items_attributes]
      items.each do |ix, item|
        params[:order][:item_ids] << item[:id]
      end
      params[:order].delete("items_attributes")
      super
    end

    def update
      params[:order][:item_ids] = []
      items = params[:order][:items_attributes]
      items.each do |ix, item|
        if item[:_destroy] == "1"
          next
        end
        params[:order][:item_ids] << item[:id]
      end
      params[:order].delete("items_attributes")

      order = Order.find(params[:id])
      order.items.destroy_all
      params[:order][:item_ids].each do |item_id|
        order.items << Item.find(item_id)    
      end
      params[:order].delete("item_ids")
      super
    end

  end

  index title: "Ordenes" do
    column "ID", :id
    column "Descripción", :description
    column "Fecha Creación", :created_at
    column "Num Orden", :order_number
    column "Futura ID" do |order|
      User.find(order.user_ids.first).external_id
    end
    column "Nombre" do |order|
      "#{User.find(order.user_ids.first).first_name} #{User.find(order.user_ids.first).last_name}"
    end
    column "Item" do |order|
      items = ""
      order.item_ids.each do |item_id|
        item = Item.find(item_id)
        items += "#{item.name}<br/>"
      end
      items.html_safe
    end
    column "Puntos" do |order|
      volume = 0
      order.item_ids.each do |item_id|
        item = Item.find(item_id)
        volume += item.volume
      end
      volume
    end
    
    actions defaults: true
  end

  form do |f|

    f.semantic_errors *f.object.errors.keys
    f.object.created_at = DateTime.now unless f.object.created_at

    f.inputs "Información de la orden" do

      f.input :description, lablel: "Descripción"
      f.input :order_number, lablel: "Número de Orden"
      f.input :created_at, label: "Creación", as: :datepicker 

      if params[:user_id]
      
        f.object.users << User.find(params[:user_id])

        f.inputs "Distribuidor" do
          f.input :user_ids, input_html: { value: params[:user_id]}, as: :hidden
          f.has_many :users, new_record: false do |a|
            a.input :external_id, label: "ID Omein", input_html: { disabled: true, style: "background-color: #d3d3d3;" }
            a.input :first_name, label: "Nombres", input_html: { disabled: true, style: "background-color: #d3d3d3;" }
            a.input :last_name, label: "Apellidos", input_html: { disabled: true, style: "background-color: #d3d3d3;" }
          end
        end
      else
        f.input :user_ids, label: "ID Omein", as: :select, 
          collection: User.all.sort_by{|user| user.external_id}
          .map{|user| ["#{user.external_id} - #{user.first_name} #{user.last_name}", user.id]}, 
          include_blank: false
      end
      
      #f.input :item_ids, label: "Item", as: :select, collection: Item.all.map {|item| ["#{item.company}-#{item.name}", item.id]}.sort,
      #  include_blank: false

      #item_collection = Item.all.map {|item| ["#{item.company}-#{item.name}", item.id]}.sort
      #item_collection += Item.all.map {|item| ["#{item.company}-#{item.name}", item.id]}.sort
      #item_collection += Item.all.map {|item| ["#{item.company}-#{item.name}", item.id]}.sort
      #item_collection += Item.all.map {|item| ["#{item.company}-#{item.name}", item.id]}.sort
      #f.input :items, as: :select, collection: Item.all.map {|item| ["#{item.company}-#{item.name}", item.id]}.sort, include_blank: false
      #f.input :item_ids, label: "Productos", as: :check_boxes, collection: item_collection, 
      #  include_blank: false
      
      #f.input :item, as: :select, collection: Item.all.map {|item| "#{item.company}-#{item.name}"}.sort, include_blank: false

      #f.inputs "Usuario" do
      #  f.has_many :users, new_record: false do |a|
      #    a.input :external_id, label: "ID Omein", input_html: { disabled: true, style: "background-color: #d3d3d3;" }
      #  end
      #end
      omein_item_collection = Item.where(company: PranaCompPlan::COMPANY_PRANA).map {|item| ["#{item.name}", item.id]}.sort
      f.inputs "Productos" do
        f.has_many :items, new_record: true, allow_destroy: true do |a|
         a.input :id, as: :select, collection: omein_item_collection, include_blank: false
        end
      end
      #f.input :user_ids, as: :select, collection: User.all.map {|user| user.external_id}, include_blank: false
      #f.input :item_ids, as: :select, collection: Item.all.map {|item| "#{item.company}-#{item.name}"}.sort, include_blank: false
    end
    f.actions   

  end

  csv do
    column "ID" do |order|
      order.id
    end
    column "Descripción" do |order|
      order.description
    end
    column "Fecha Creación" do |order|
      order.created_at
    end
    column "Num Orden" do |order|
      order.order_number
    end
    column "Futura ID" do |order|
      User.find(order.user_ids.first).external_id
    end
    column "Nombre" do |order|
      "#{User.find(order.user_ids.first).first_name} #{User.find(order.user_ids.first).last_name}"
    end
    column "Item" do |order|
      items = ""
      order.item_ids.each do |item_id|
        item = Item.find(item_id)
        items += "#{item.name}<br/>"
      end
      items.html_safe
    end
    column "Puntos" do |order|
      volume = 0
      order.item_ids.each do |item_id|
        item = Item.find(item_id)
        volume += item.volume
      end
      volume
    end
  end

end
