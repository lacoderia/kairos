require 'rails_helper'
feature 'UsersController' do
  include ActiveJob::TestHelper

  context 'user login and logout ' do
  
    let!(:user_01){create(:user)}

    it 'should login and set devise_token headers' do

      access_token_1, uid_1, client_1, expiry_1, token_type_1 = nil

      login_with_service user = { email: user_01.email, password: "12345678" }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      expect(access_token_1).not_to be nil
      expect(uid_1).not_to be nil
      expect(client_1).not_to be nil
      expect(expiry_1).not_to be nil
      expect(token_type_1).not_to be nil
      
      logout

    end

  end

  context 'user registration through invitation' do

    let!(:upline){create(:user)}
    let!(:invitation){create(:invitation, user: upline, token: "token-test-string")}

    it 'should register a new user and set devise_token headers' do

      new_user = { email: "new_user@parana.mx", first_name: "New", last_name: "User", password: "newuser", password_confirmation: "newuser", phone: "434343434", external_id: upline.external_id + 1, sponsor_external_id: upline.external_id, placement_external_id: upline.external_id} 

      access_token_1, uid_1, client_1, expiry_1, token_type_1 = nil
      page = register_with_service new_user, invitation.token 
      response = JSON.parse(page.body)
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      expect(access_token_1).not_to be nil
      expect(response["user"]["email"]).to eql new_user[:email]

      #Move email testing to invitations controller
      #expect(SendEmailJob).to have_been_enqueued.with("welcome", global_id(User.last), nil)
      #perform_enqueued_jobs { SendEmailJob.perform_later("welcome", User.last, nil) } 
        
      logout

      access_token_1, uid_1, client_1, expiry_1, token_type_1 = nil
      page = login_with_service user = { email: new_user[:email], password: 'invalidpassword' }
      response = JSON.parse(page.body)
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      expect(access_token_1).to be nil
      expect(response["errors"][0]["title"]).to eql "El correo electrónico o la contraseña son incorrectos."

      #page = get_session 
      #response = JSON.parse(page.body)
      #expect(response['success']).to be false 
      #expect(response['error']).to eql "No has iniciado sesión."

      access_token_1, uid_1, client_1, expiry_1, token_type_1 = nil
      page = login_with_service user = { email: new_user[:email], password: new_user[:password] }
      response = JSON.parse(page.body)
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      expect(access_token_1).not_to be nil
      expect(response["user"]["email"]).to eql new_user[:email]
    
      #page = get_session 
      #response = JSON.parse(page.body)
      #expect(response['success']).to be true 
      #expect(response['result']['first_name']).to eql "test"

    end

  end

end
