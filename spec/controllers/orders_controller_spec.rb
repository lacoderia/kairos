feature 'OrdersController' do
  include ActiveJob::TestHelper    

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

  context 'create_with_items' do

    it 'should create an order with products of a company' do
      
      Capybara.current_driver = :selenium_chrome
      visit get_device_session_id_cards_path

      sleep(3)

      doc = Nokogiri::HTML(page.body)

      device_session_id = doc.at("#device_session_id").inner_html
      token = doc.at("#card_token").inner_html

      expect(device_session_id).not_to eq ""
      expect(token).not_to eq "" 
      
      Capybara.use_default_driver 
      
      login_with_service user = { email: user_01.email, password: "12345678" }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1

      user_01.shipping_addresses << ShippingAddress.first

      #CREATE CARD
      create_card_request = {token: token, device_session_id: device_session_id, company: "prana", card: {company: "PRANA"}} 
      
      with_rack_test_driver do
        page.driver.post cards_path, create_card_request 
      end
      
      response = JSON.parse(page.body)
      expect(response["card"]["openpay_id"]).to eq token
      expect(response["card"]["primary"]).to eq true
      expect(response["card"]["company"]).to eq "PRANA"

      #CHECK SHIPPING PRICE WITHOUT ADDRESS
      check_shipping_request = {shipping_address_id: nil, items: [
                                  {id: Item.first.id, amount: 3},
                                  {id: Item.last.id, amount: 1}]}
      
      with_rack_test_driver do
        page.driver.post calculate_shipping_price_orders_path, check_shipping_request 
      end
      
      response = JSON.parse(page.body)
      expect(response["shipping_price"]).to eq 0

      #CHECK SHIPPING PRICE
      check_shipping_request = {shipping_address_id: user_01.shipping_addresses.first.id, items: [
                                  {id: Item.first.id, amount: 3},
                                  {id: Item.last.id, amount: 1}]}
      
      with_rack_test_driver do
        page.driver.post calculate_shipping_price_orders_path, check_shipping_request 
      end
            
      response = JSON.parse(page.body)
      expect(response["shipping_price"]).to eq 250
      shipping_price = response["shipping_price"]
      
      create_order_request = {total: 400 + shipping_price, company: "prana", shipping_address_id: user_01.shipping_addresses.first.id,
                              card_id: token, device_session_id: device_session_id, items: [
                                {id: Item.first.id, amount: 3},
                                {id: Item.last.id, amount: 1}]}

      with_rack_test_driver do
        page.driver.post create_with_items_orders_path, create_order_request 
      end
      
      response = JSON.parse(page.body)
      expect(response["order"]["items"][0]['amount']).to eq 3
      expect(response["order"]["items"][1]['amount']).to eq 1

    end

  end

end
