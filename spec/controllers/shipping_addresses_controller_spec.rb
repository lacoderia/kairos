feature 'ShippingAddressesController' do

  context 'shipping address creation' do

    let!(:user){create(:user)}

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

    it 'should not create shipping addresses not associated to a user' do

      new_address = { address: "nueva rosalina 45", zip: "03388", country: "Mexico", state: "CDMX", location: "MX"}
      
      expect(user.shipping_addresses.count).to eql 0
      
      login_with_service u = { email: user.email, password: '12345678' }
      
      with_rack_test_driver do
        page.driver.post shipping_addresses_path, { shipping_address: new_address}
      end
      
      response = JSON.parse(page.body)

      expect(page.status_code).to eql 500
      expect(response["errors"][0]["title"]).to eql "Error autenticando encabezados."
      expect(user.shipping_addresses.count).to eql 0

    end

  end

end
