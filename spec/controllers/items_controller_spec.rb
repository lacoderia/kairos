feature 'ItemsController' do

  let!(:user_01){ create(:user, :confirmed) }
  let!(:item_01){ create(:item, company: "OMEIN", active: true) }
  let!(:item_02){ create(:item, company: "OMEIN", active: true) }
  let!(:item_03){ create(:item, company: "OMEIN", active: false) }
  let!(:item_04){ create(:item, company: "PRANA", active: true) }

  context 'by_company' do

    it 'should return all the products by company' do
      login_with_service user = { email: user_01.email, password: "12345678" }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1

      visit "#{by_company_items_path}?company=omein"
      
      response = JSON.parse(page.body)
      expect(response["items"].count).to eq 2
      expect(response["items"][0]["id"]).to eq item_01.id
    end
    
  end

end
