module TestingSupport
  module DeviseHelpers

    def login_with_service user
      with_rack_test_driver do
        page.driver.post user_session_path, { user: user}
      end
      return page
    end

    def register_with_service user, token
      with_rack_test_driver do
        page.driver.post user_registration_path, { user: user, token: token }
      end
      return page
    end

    def logout
      visit(logout_path)
      set_headers "", "", "", "", ""
    end

    def get_session
      visit(session_path)
      return page
    end

    def get_headers
      [page.response_headers["access-token"], page.response_headers["uid"], page.response_headers["client"], page.response_headers["expiry"], page.response_headers["token-type"]]
    end

    def set_headers access_token, uid, client, expiry, token_type
      page.driver.header "access-token", access_token
      page.driver.header "uid", uid
      page.driver.header "client", client
      page.driver.header "expriy", expiry
      page.driver.header "token-type", token_type      
    end

    #TODO: SETUP ADMIN 
    def login_as_admin admin
      visit(new_admin_user_session_path)
      fill_in 'admin_user_email', with: admin.email
      fill_in 'admin_user_password', with: admin.password
      click_button 'Login'
    end

    def logout_as_admin
       visit(destroy_admin_user_session_path)
    end

  end
end

