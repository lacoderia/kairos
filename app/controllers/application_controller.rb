class ApplicationController < ActionController::Base
  #protect_from_forgery with: :exception

  def authenticate_admin_user!
    if admin_user_signed_in?
      super
    else
      redirect_to new_admin_user_session_path
    end
  end

  def access_denied(exception)
    redirect_to "/422.html", :alert => exception.message
  end

end
