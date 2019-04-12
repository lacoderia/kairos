ActiveAdmin.register Item, as: "Productos" do

  actions :all, :except => [:show]

  permit_params :company, :name, :description, :price, :commissionable_value, :volume, :image, :active

  index title: "Productos" do
  
    column "Nombre", :name
    column "Descripción", :description
    column "Precio", :price
    column "Valor comisionable", :commissionable_value
    column "Empresa", :company
    column "Imagen", :image do |item|
      image_tag item.image, style: 'height:50px;width:50px;'
    end
    column "Activo", :active
    actions defaults: true   
  end

  form do |f|

    f.inputs "Producto" do
      f.input :name, label: "Nombre"
      f.input :description, label: "Descripción"
      f.input :price, label: "Precio"
      f.input :commissionable_value, label: "Valor comisionable"
      f.input :company, label: "Empresa", as: :select, 
        collection:[ [OmeinCompPlan::COMPANY_OMEIN], [PranaCompPlan::COMPANY_PRANA] ], include_blank: false
      f.file_field :image, label: "Imagen"
      f.input :active, label: "Activo"
    end
    f.actions

  end

end
