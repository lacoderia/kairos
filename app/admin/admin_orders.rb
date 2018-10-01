ActiveAdmin.register Order, as: "Ordenes" do

  actions :all, :except => [:show]

  permit_params :description, :order_number, :user_ids, :item_ids

  form do |f|

    f.semantic_errors *f.object.errors.keys

    f.inputs "Información de la orden" do

      f.input :description, lablel: "Descripción"
      f.input :order_number, lablel: "Número de Orden"

      if params[:user_id]
      
        f.object.users << User.find(params[:user_id])

        f.inputs "Distribuidor" do
          f.input :user_ids, input_html: { value: params[:user_id]}, as: :hidden
          f.has_many :users, new_record: false do |a|
            a.input :external_id, label: "ID Omein", input_html: { disabled: true, style: "background-color: #d3d3d3;" }
          end
        end
      else
        f.input :user_ids, label: "ID Omein", as: :select, collection: User.all.map {|user| [user.external_id, user.id]}.sort, 
          include_blank: false
      end
      
      f.input :item_ids, label: "Item", as: :select, collection: Item.all.map {|item| ["#{item.company}-#{item.name}", item.id]}.sort,
        include_blank: false
      
      #f.input :item, as: :select, collection: Item.all.map {|item| "#{item.company}-#{item.name}"}.sort, include_blank: false

      #f.inputs "Usuario" do
      #  f.has_many :users, new_record: false do |a|
      #    a.input :external_id, label: "ID Omein", input_html: { disabled: true, style: "background-color: #d3d3d3;" }
      #  end
      #end
      #f.inputs "Productos" do
      #  f.has_many :items, new_record: true, allow_destroy: true do |a|
      #   a.input :item, as: :select, collection: Item.all.map {|item| ["#{item.company}-#{item.name}", item.id]}.sort, include_blank: false
      #  end
      #end
      #f.input :user_ids, as: :select, collection: User.all.map {|user| user.external_id}, include_blank: false
      #f.input :item_ids, as: :select, collection: Item.all.map {|item| "#{item.company}-#{item.name}"}.sort, include_blank: false
    end
    f.actions   

  end

end
