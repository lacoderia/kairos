feature 'PasswordsController' do

  let!(:user) {create(:user) }

  context 'Password recovery and change' do

    it 'Validates password recovery instructions and password reset' do
      password_recovery_request = { utf8: 'V', user: { email: user.email } }
      page1 = nil
      with_rack_test_driver do
        page1 = page.driver.post user_password_path, password_recovery_request
      end
      response = JSON.parse(page1.body)
      token = response['token']
      expect(token.length).to be > 1
      
      #Incorrect email
      incorrect_password_recovery_request = { utf8: 'V', user: { email: "another@email.com" } }
      page1 = nil
      with_rack_test_driver do
        page1 = page.driver.post user_password_path, incorrect_password_recovery_request
      end
      response = JSON.parse(page1.body)
      expect(page.status_code).to be 500
      expect(response['errors'][0]["title"]).to eql "No se encontró usuario con ese email."

      #Incorrect password reset
      old_password = user.password
      new_password = "10002000"
      
      incorrect_password_reset_request = { utf8: 'V', user: { reset_password_token: token, password: new_password, password_confirmation: "20001000" } }
      page2 = nil
      with_rack_test_driver do
        page2 = page.driver.put user_password_path, incorrect_password_reset_request
      end
      response = JSON.parse(page2.body)
      expect(page.status_code).to be 500
      expect(response['errors'][0]["title"]).to eql "doesn't match Password"
      
      password_reset_request = { utf8: 'V', user: { reset_password_token: token, password: new_password, password_confirmation: new_password } }
      page3 = nil
      with_rack_test_driver do
        page3 = page.driver.put user_password_path, password_reset_request
      end
      response = JSON.parse(page3.body)

      user = User.first
      expect(user.valid_password?(new_password)).to be true
      expect(user.valid_password?(old_password)).to be false

    end

  end

end

