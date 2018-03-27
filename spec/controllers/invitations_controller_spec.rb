feature 'InvitationsController' do
  include ActiveJob::TestHelper

  let!(:user){ create(:user, :confirmed) }
  let!(:user_02){ create(:user, :confirmed) }
  
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

        expect(SendEmailJob).to have_been_enqueued.with("send_invitation", global_id(user), global_id(Invitation.last))
        perform_enqueued_jobs { SendEmailJob.perform_later("send_invitation", user, Invitation.last) } 

        expect(Email.count).to eql 1
        
    end

    it 'raises error creating incorrect invitation' do
      new_invitation = { recipient_name: "Pedrito Bodoque", recipient_email: "pedrito_bodoque@gmail.com", user_id: user_02.id}
      login_with_service u = { email: user.email, password: '12345678' }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers

      #witout headers
      with_rack_test_driver do
        expect {page.driver.post invitations_path, { invitation: new_invitation}}.to raise_error.with_message('You are not authorized to access this page.')
      end
        
      #without valid user ID
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1
      with_rack_test_driver do
        expect {page.driver.post invitations_path, { invitation: new_invitation}}.to raise_error.with_message('You are not authorized to access this page.')
      end
      
    end

  end

  context 'invitations by user' do

    let!(:invitation_01){ create(:invitation, user: user) }
    let!(:invitation_02){ create(:invitation, user: user) }
    let!(:invitation_03){ create(:invitation, user: user_02) }

    it 'should get invitations list for logged in user' do
      
      login_with_service u = { email: user.email, password: '12345678' }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1

      visit by_user_invitations_path

      response = JSON.parse(page.body)
      expect(response["invitations"].count).to eql 2

      logout 

      expect {visit by_user_invitations_path}.to raise_error.with_message('You are not authorized to access this page.')

    end

  end
end

