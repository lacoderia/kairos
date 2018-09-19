feature 'ShippingAddressesController' do

  context 'shipping address creation' do

    let!(:user){create(:user, :confirmed)}

    it 'should successfully create shipping address' do
        
      new_address = { address: "nueva rosalina 45", zip: "03388", country: "Mexico", state: "CDMX", location: "MX"}

      expect(user.shipping_addresses.count).to eql 0
        
      login_with_service u = { email: user.email, password: '12345678' }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1

      with_rack_test_driver do
        page.driver.post shipping_addresses_path, { shipping_address: new_address}
      end
      
      response = JSON.parse(page.body)

      expect(response["shipping_address"]["address"]).to eql new_address[:address]
      expect(user.shipping_addresses.count).to eql 1

      new_address_02 = { address: "nueva rosalina 55", zip: "03389", country: "Mexico", state: "CDMX", location: "MX"}

      with_rack_test_driver do
        page.driver.post shipping_addresses_path, { shipping_address: new_address_02}
      end
      
      response = JSON.parse(page.body)

      expect(response["shipping_address"]["address"]).to eql new_address_02[:address]
      expect(user.shipping_addresses.count).to eql 2

    end

    it 'should not create shipping addresses without a logged in user' do

      new_address = { address: "nueva rosalina 45", zip: "03388", country: "Mexico", state: "CDMX", location: "MX"}
      
      expect(user.shipping_addresses.count).to eql 0
      
      login_with_service u = { email: user.email, password: '12345678' }

      #witout headers
      with_rack_test_driver do
        expect {page.driver.post shipping_addresses_path, { shipping_address: new_address}}.to raise_error.with_message('You are not authorized to access this page.')
      end

    end

  end

  context 'shipping address update' do
    
    let!(:user_01){create(:user, :confirmed, :with_address)}
    let!(:user_02){create(:user, :confirmed, :with_address)}

    it 'should update shipping address with owner user, and throw error with other user' do

      login_with_service u = { email: user_01.email, password: '12345678' }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1

      updated_address = { address: "nueva rosalina 45", zip: "03388", country: "Mexico", state: "CDMX", location: "MX"}
      with_rack_test_driver do
        page.driver.put "#{shipping_addresses_path}/#{user_01.shipping_addresses.first.id}", {shipping_address: updated_address}
      end
      
      #new address
      response = JSON.parse(page.body)
      expect(response["shipping_address"]["address"]).to eql updated_address[:address]

      #without valid user ID
      with_rack_test_driver do
        expect {page.driver.put "#{shipping_addresses_path}/#{user_02.shipping_addresses.first.id}", {shipping_address: updated_address}}.to raise_error.with_message('You are not authorized to access this page.')
      end

    end

  end

  context 'get all shipping addresses for user' do
    
    let!(:user_01){create(:user, :confirmed, :with_address)}
    let!(:user_02){create(:user, :confirmed, :with_address)}
    let!(:shipping_address){create(:shipping_address, users: [user_02])}

    it 'should get shipping addresses for logged in users' do
      
      login_with_service u = { email: user_01.email, password: '12345678' }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1

      visit get_all_for_user_shipping_addresses_path      
      response = JSON.parse(page.body)
      expect(response["shipping_addresses"].count).to eql 1 

      logout

      login_with_service u = { email: user_02.email, password: '12345678' }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1

      visit get_all_for_user_shipping_addresses_path      
      response = JSON.parse(page.body)
      expect(response["shipping_addresses"].count).to eql 2
      
      logout

      expect {page.driver.get get_all_for_user_shipping_addresses_path}.to raise_error.with_message('You are not authorized to access this page.')

    end

  end

end
