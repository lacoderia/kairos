ActiveAdmin.register Order, as: "Prana Ordenes" do

  actions :all, :except => [:show]

  filter :created_at, as: :date_range, label: "Fecha de creación"
  filter :order_number, label: "Número de orden"
  filter :users, collection: -> { User.all.map { |user| [user.external_id, user.id] }.sort }

  permit_params :description, :order_number, :user_ids, :created_at, :shipping_address_id, :shipping_price, item_ids: [], items_attributes: [:id, :item, :_destroy]

  controller do

    def scoped_collection
      Order.joins(:items).where("items.company = ? AND orders.order_status != ?", PranaCompPlan::COMPANY_PRANA, "VALIDATING").distinct
    end

    def create
      if params[:order][:items_attributes]
        params[:order][:item_ids] = []
        items = params[:order][:items_attributes]
        items.each do |ix, item|
          params[:order][:item_ids] << item[:id]
        end
        params[:order].delete("items_attributes")
      end
      
      if params[:order][:created_at].to_datetime.offset == 0
        params[:order][:created_at] = params[:order][:created_at].in_time_zone.to_s 
      end

      super
    end

    def update
      if params[:order][:items_attributes] 
        params[:order][:item_ids] = []
        items = params[:order][:items_attributes]
        destroy_count = item_count = 0
        items.each do |ix, item|
          item_count += 1
          if item[:_destroy] == "1"
            destroy_count += 1
            next
          end
          params[:order][:item_ids] << item[:id]
        end
        if destroy_count == item_count
          raise 'No pueden haber ordenes sin items'
        end
        params[:order].delete("items_attributes")

        order = Order.find(params[:id])
        original_item_ids = [] 
        order.items.each do |item| 
          original_item_ids << item.id.to_s
        end

        order.items.destroy_all
        params[:order][:item_ids].each do |item_id|
          order.items << Item.find(item_id)    
        end
      end

      email_update, update_volume = false
      if order.created_at.to_s != params[:order][:created_at] 
        if params[:order][:created_at].to_datetime.offset == 0
          params[:order][:created_at] = params[:order][:created_at].in_time_zone.to_s 
        end
        
        email_update = true
        update_volume = true
        order.update_column(:created_at, params[:order][:created_at]) 
      end
      if params[:order][:item_ids].sort != original_item_ids.sort
        email_update = true
        update_volume = true
      end
      if params[:order][:shipping_address_id] != order.shipping_address_id.to_s
        email_update = true
        order.update_column(:shipping_address_id, params[:order][:shipping_address_id])
      end
      if params[:order][:shipping_price].to_f != order.shipping_price
        email_update = true
        order.update_column(:shipping_price, params[:order][:shipping_price])
        order.update_column(:total_price,  order.calculate_total_price)
      end
      if email_update
        SendEmailJob.perform_later("order", order.users.first, order)
      end
      if update_volume
        order.update_volume_for_users
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
    column "Dirección" do |order|
      order.shipping_address.to_s
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
      order.total_item_volume
    end
    column "Precio de productos" do |order|
      order.total_item_price
    end
    column "Precio de envío", :shipping_price 
    column "Precio total" do |order|
      if order.total_price
        order.total_price
      else
        order.calculate_total_price
      end
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

      if not f.object.users.empty?
        f.inputs "Dirección de envío" do
          f.input :shipping_address, label: "Dirección", as: :select, 
            collection: f.object.users.first.shipping_addresses.map{|sa| [sa.to_s, sa.id]}
        end
      end
      
      prana_item_collection = Item.where(company: PranaCompPlan::COMPANY_PRANA, active: true).map {|item| ["#{item.name}", item.id]}.sort
      f.inputs "Productos" do
        f.has_many :items, new_record: true, allow_destroy: true do |a|
         a.input :id, as: :select, collection: prana_item_collection, include_blank: false
        end
      end
      f.input :shipping_price, label: "Precio de envío" 
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
    column "Direccion" do |order|
      order.shipping_address.to_s      
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
      order.total_item_volume
    end
    column "Precio de productos" do |order|
      order.total_item_price
    end
    column "Precio de envio" do |order|
      order.shipping_price
    end
    column "Precio total" do |order|
      if order.total_price
        order.total_price
      else
        order.calculate_total_price
      end
    end
  end

end
