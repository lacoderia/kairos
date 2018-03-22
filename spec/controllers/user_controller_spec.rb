feature 'UsersController' do

  context 'user login and logout ' do
  
    let!(:user_01){create(:user, :confirmed)}

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

  context 'user update' do
    
    let!(:user_01){create(:user, :confirmed)}
    let!(:user_02){create(:user, :confirmed)}

    it 'should change password and email from a user' do

      login_with_service user = { email: user_01.email, password: "12345678" }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1

      #Update first_name and password
      update_user_request = {user:{first_name: "Arturo", password: 'ABCDEFG123', password_confirmation: 'ABCDEFG123'} }
      with_rack_test_driver do
        page.driver.put "#{users_path}/#{user_01.id}", update_user_request 
      end

      response = JSON.parse(page.body)
      expect(response['user']['first_name']).to eql "Arturo"

      page = get_session 
      response = JSON.parse(page.body)
      expect(response['user']['first_name']).to eql "Arturo"
      logout

      #Login with new password
      page = login_with_service updated_user = { email: user_01.email, password: 'ABCDEFG123' }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1
      
      response = JSON.parse(page.body)
      expect(response['user']['first_name']).to eql "Arturo"

      #Error, password doesn't match 
      update_user_request = {user:{password: 'ABCDEFG1234', password_confirmation: 'ABCDEFG12345'} }
      with_rack_test_driver do
        page.driver.put "#{users_path}/#{user_01.id}", update_user_request 
      end
      response = JSON.parse(page.body)
      expect(response['errors'][0]["title"]).to eql "doesn't match Password"

      #byebug
      
      #Update email      
      update_user_request = {user:{email: "new_test@email.com"} }
      with_rack_test_driver do
        page.driver.put "#{users_path}/#{user_01.id}", update_user_request 
      end
      
      response = JSON.parse(page.body)
      expect(response['user']['email']).to eql "new_test@email.com"
      
      logout
      
      #Login with new email 
      user_01.reload
      page = login_with_service updated_user = { email: user_01.email, password: 'ABCDEFG123' }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1
      
      response = JSON.parse(page.body)
      expect(response['user']['email']).to eql "new_test@email.com"

      logout

      #Update email from another user
      login_with_service user = { email: user_02.email, password: "12345678" }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1

      update_user_request = {user:{email: "new_test_2@email.com"} }
      with_rack_test_driver do
        expect {page.driver.put "#{users_path}/#{user_01.id}", update_user_request}.to raise_error.with_message('You are not authorized to access this page.')
      end
      
    end

  end

  context 'user registration through invitation' do

    let!(:upline){create(:user, :confirmed)}
    let!(:invitation){create(:invitation, user: upline, token: "token-test-string")}

    it 'should register a new user and set devise_token headers' do

      new_user = { email: "new_user@parana.mx", first_name: "New", last_name: "User", password: "newuser", password_confirmation: "newuser", phone: "434343434", external_id: upline.external_id + 1, sponsor_external_id: upline.external_id, placement_external_id: upline.external_id} 

      access_token_1, uid_1, client_1, expiry_1, token_type_1 = nil

      expect(invitation.used).to be false
      
      page = register_with_service new_user, invitation.token 

      visit "#{user_confirmation_path}?config=default&confirmation_token=#{User.last.confirmation_token}&redirect_url="
      logout
      login_with_service user = { email: new_user[:email], password: new_user[:password] }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers

      response = JSON.parse(page.body)
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      expect(access_token_1).not_to be nil
      expect(response["user"]["email"]).to eql new_user[:email]
      
      invitation.reload 
      expect(invitation.used).to be true 

      logout

      access_token_1, uid_1, client_1, expiry_1, token_type_1 = nil
      page = login_with_service user = { email: new_user[:email], password: 'invalidpassword' }
      response = JSON.parse(page.body)
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      expect(access_token_1).to be nil
      expect(response["errors"][0]["title"]).to eql "El correo electrónico o la contraseña son incorrectos."

      page = get_session 
      response = JSON.parse(page.body)
      expect(page.status_code).to be 500
      expect(response["errors"][0]["title"]).to eql "No se ha iniciado sesión."

      access_token_1, uid_1, client_1, expiry_1, token_type_1 = nil
      page = login_with_service user = { email: new_user[:email], password: new_user[:password] }
      response = JSON.parse(page.body)
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      expect(access_token_1).not_to be nil
      expect(response["user"]["email"]).to eql new_user[:email]
    
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1
      page = get_session 
      response = JSON.parse(page.body)
      expect(response["user"]["email"]).to eql new_user[:email]

    end

  end

end
