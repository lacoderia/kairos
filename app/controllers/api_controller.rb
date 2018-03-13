class ApiController < ActionController::Base
  include DeviseTokenAuth::Concerns::SetUserByToken 
  respond_to :json
end

