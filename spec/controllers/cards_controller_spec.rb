feature 'CardsController' do

  context 'Managing cards' do

    let!(:user_01){create(:user, :confirmed)}

    it 'should create a card, charge it and destroy it' do

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

      #CREATE
      create_card_request = {token: token, device_session_id: device_session_id, country: "MX", company: "prana"} 
      
      with_rack_test_driver do
        page.driver.post cards_path, create_card_request 
      end
      
      response = JSON.parse(page.body)
      expect(response["card"]["openpay_id"]).to eq token
      expect(response["card"]["primary"]).to eq true
      expect(response["card"]["company"]).to eq "PRANA"

      card_id = response["card"]["id"]      

      #DESTROY
      destroy_card_request = {id: card_id, company: "PRANA"}
      with_rack_test_driver do
        page.driver.post delete_cards_path, destroy_card_request 
      end
      
      expect(page.status_code).to eq 500
      response = JSON.parse(page.body)
      expect(response["errors"][0]["title"]).to eq "Necesitas tener al menos una tarjeta"

      Capybara.current_driver = :selenium_chrome

      visit get_device_session_id_cards_path

      sleep(3)

      doc = Nokogiri::HTML(page.body)

      device_session_id = doc.at("#device_session_id").inner_html
      token = doc.at("#card_token").inner_html

      expect(device_session_id).not_to eq ""
      expect(token).not_to eq "" 

      Capybara.use_default_driver

      #CREATE 2nd CARD
      create_card_request = {token: token, device_session_id: device_session_id, country: "US", company: "PRANA"} 
      
      with_rack_test_driver do
        page.driver.post cards_path, create_card_request 
      end

      response = JSON.parse(page.body)
      expect(response["card"]["openpay_id"]).to eq token
      expect(response["card"]["primary"]).to eq false 
      card2_id = response["card"]["id"]
      
      #SET PRIMARY
      set_primary_card_request = {id: card2_id, company: "PRANA"} 
      
      with_rack_test_driver do
        page.driver.post set_primary_cards_path, set_primary_card_request 
      end

      response = JSON.parse(page.body)
      expect(response["card"]["id"]).to eq card2_id
      expect(response["card"]["primary"]).to eq true

      #GET ALL CARDS
      visit "#{all_cards_path}?company=prana"
      
      response = JSON.parse(page.body)
      expect(response["cards"].count).to eq 2
      expect(response["cards"][1]["primary"]).to eq true
      expect(response["cards"][1]["id"]).to eq card2_id

      #DESTROY
      destroy_card_request = {id: card2_id, company: "prana"}
      with_rack_test_driver do
        page.driver.post delete_cards_path, destroy_card_request 
      end
      
      response = JSON.parse(page.body)
      expect(response["cards"].count).to eq 1
      expect(response["cards"][0]["primary"]).to eq true
      expect(response["cards"][0]["id"]).to eq card_id

    end

  end

end
