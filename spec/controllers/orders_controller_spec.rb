feature 'OrdersController' do

  let!(:user_01){ create(:user, :confirmed) }
  let!(:order_01){ create(:order, :with_address, users: [user_01]) }
  let!(:order_02){ create(:order, users: [user_01]) }

  context 'all' do

    it 'should return all the orders by company' do
      login_with_service user = { email: user_01.email, password: "12345678" }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1
      
      visit "#{all_orders_path}?company=prana"
      
      response = JSON.parse(page.body)
      expect(response["orders"].count).to eq 2
      expect(response["orders"][0]["id"]).to eq order_02.id
    end
    
  end

end
