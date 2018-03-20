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
      
      byebug
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
