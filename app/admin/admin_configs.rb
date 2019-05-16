ActiveAdmin.register Config, :as => "Configuraciones" do

  actions :all, :except => [:show, :destroy, :new]

  permit_params :key, :value

  config.filters = false

  index :title => "Configuraciones" do
    column "Concepto", :key
    column "Valor", :value
    actions :defaults => true
  end

  form do |f|
    f.inputs "Detalles de configuraciones" do
      f.input :key, label: "Concepto", :input_html => { :disabled => true, :style => "background-color: #d3d3d3;" }
      f.input :value, label: "Valor"
    end
    f.actions
  end

end
