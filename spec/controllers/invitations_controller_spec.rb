feature 'InvitationsController' do
  include ActiveJob::TestHelper

  let!(:user){ create(:user) }
  
    context 'invitation creation' do

      it 'should successfully create invitation' do
        new_invitation = { recipient_name: "Pedrito Bodoque", recipient_email: "pedrito_bodoque@gmail.com", user_id:user.id}
        
        login_with_service u = { email: user.email, password: '12345678' }
        access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
        set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1

        with_rack_test_driver do
          page.driver.post invitations_path, { invitation: new_invitation}
        end
        
        response = JSON.parse(page.body)
        expect(response["invitation"]["recipient_email"]).to eql "pedrito_bodoque@gmail.com"
      
        expect(Email.count).to eql 0

        expect(SendEmailJob).to have_been_enqueued.with("send_invitation", global_id(User.last), global_id(Invitation.last))
        perform_enqueued_jobs { SendEmailJob.perform_later("send_invitation", User.last, Invitation.last) } 

        expect(Email.count).to eql 1
        
    end

    it 'raises error on incorrect invitation' do
      new_invitation = { recipient_name: "Pedrito Bodoque", recipient_email: "dmiramon@gmail.com", user_id:-1}
      login_with_service u = { email: user.email, password: '12345678' }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers

      with_rack_test_driver do
        page.driver.post invitations_path, { invitation: new_invitation}
      end
      response = JSON.parse(page.body)

      expect(page.status_code).to be 500
      expect(response["errors"][0]["title"]).to eql "Error autenticando encabezados."
        
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1
      with_rack_test_driver do
        page.driver.post invitations_path, { invitation: new_invitation}
      end
      response = JSON.parse(page.body)

      expect(page.status_code).to be 500 
      
    end

  end
end

