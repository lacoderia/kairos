ActiveAdmin.register Order, as: "Ordenes_no_verificadas" do

  actions :all, :except => [:show, :new, :edit]

  filter :created_at, as: :date_range, label: "Fecha de creación"
  filter :order_number, label: "Número de orden"
  filter :company, label: "Empresa"
  filter :users, collection: -> { User.all.map { |user| [user.external_id, user.id] }.sort } 

  permit_params :description, :order_number, :user_ids, :created_at, :shipping_address_id, :shipping_price, item_ids: [], items_attributes: [:id, :item, :_destroy]

  controller do

    def scoped_collection
      Order.where("orders.order_status = ?", "VALIDATING").distinct
    end

  end

  index title: "Ordenes no verificadas" do
    column "ID", :id
    column "Empresa", :company
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

  csv do
    column "ID" do |order|
      order.id
    end
    column "Empresa" do |order|
      order.company
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
