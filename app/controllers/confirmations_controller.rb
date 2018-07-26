class ConfirmationsController < Devise::ConfirmationsController
  private
  def after_confirmation_path_for(resource_name, resource)
    "http://#{ENV['FRONTEND_HOST']}" 
  end
end
