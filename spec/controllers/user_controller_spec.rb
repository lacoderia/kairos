require 'rails_helper'
feature 'UsersController' do
  include ActiveJob::TestHelper
  
  let!(:user_01){create(:user)}

  context 'user login and logout ' do

    it 'should login and set devise_token headers' do

      access_token_1, uid_1, client_1, expiry_1, token_type_1 = nil

      login_with_service user = { email: user_01.email, password: "12345678" }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      expect(access_token_1).not_to be nil
      expect(uid_1).not_to be nil
      expect(client_1).not_to be nil
      expect(expiry_1).not_to be nil
      expect(token_type_1).not_to be nil

    end

    it 'should register a new user, send welcome email and logout' do

      new_user = { email: "new_user@parana.mx", first_name: "New", last_name: "User", password: "newuser", password_confirmation: "newuser", phone: "434343434"} 

      page = register_with_service new_user 
      response = JSON.parse(page.body)

      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      expect(access_token_1).not_to be nil
      expect(response["user"]["email"]).to eql new_user[:email]

      expect(SendEmailJob).to have_been_enqueued.with("welcome", global_id(User.last), nil)
      
      perform_enqueued_jobs { SendEmailJob.perform_later("welcome", User.last, nil) } 
        
      logout

    end

  end
end
