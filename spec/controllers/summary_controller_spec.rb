feature 'SummaryController' do

  period_start = Time.zone.now.beginning_of_month + 1.month
  period_end = period_start + 1.month
  
  let!(:user_01){ create(:user, :confirmed) }
  let!(:summary_01){ create(:summary, user: user_01, period_start: period_start, period_end: period_end) }
  let!(:user_02){ create(:user, :confirmed, sponsor_external_id: user_01.external_id, placement_external_id: user_01.external_id) }
  let!(:summary_02){ create(:summary, user: user_02, period_start: period_start, period_end: period_end) }
  let!(:user_03){ create(:user, :confirmed, sponsor_external_id: user_02.external_id, placement_external_id: user_02.external_id) }
  
  context 'get summary by period with downlines' do

    it 'should get summary by period for downlines' do

      login_with_service user = { email: user_01.email, password: "12345678" }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1

      visit ("#{by_period_with_downlines_summaries_path}?period_start=#{period_start}&period_end=#{period_end}")
      response = JSON.parse(page.body)

      expect(response["user"]["id"]).to eql user_01.id
      expect(response["summary"]["omein_vg"]).to eql summary_01.omein_vg
      expect(response["downlines"][0]["user"]["id"]).to eql user_02.id
      expect(response["downlines"][0]["downlines"][0]["user"]["id"]).to eql user_03.id

      logout
      
      expect {visit by_period_with_downlines_summaries_path}.to raise_error.with_message('You are not authorized to access this page.')
      
    end

  end

  context 'get summary by period and user with downlines 1 level' do

    it 'should get summary by period for downlines' do

      login_with_service user = { email: user_01.email, password: "12345678" }
      access_token_1, uid_1, client_1, expiry_1, token_type_1 = get_headers
      set_headers access_token_1, uid_1, client_1, expiry_1, token_type_1

      visit ("#{by_period_and_user_with_downlines_1_level_summaries_path}?user_id=#{user_01.id}&period_start=#{period_start}&period_end=#{period_end}")
      response = JSON.parse(page.body)

      expect(response["user"]["id"]).to eql user_01.id
      expect(response["summary"]["omein_vg"]).to eql summary_01.omein_vg
      expect(response["downlines"][0]["user"]["id"]).to eql user_02.id
      expect(response["downlines"][0]["downlines"].length).to eql 0

      visit ("#{by_period_and_user_with_downlines_1_level_summaries_path}?user_id=#{user_02.id}&period_start=#{period_start}&period_end=#{period_end}")
      response = JSON.parse(page.body)

      expect(response["user"]["id"]).to eql user_02.id
      expect(response["summary"]["omein_vg"]).to eql summary_02.omein_vg
      expect(response["downlines"][0]["user"]["id"]).to eql user_03.id
      expect(response["downlines"][0]["downlines"].length).to eql 0

      logout
      
      expect {visit by_period_and_user_with_downlines_1_level_summaries_path}.to raise_error.with_message('You are not authorized to access this page.')
      
    end

  end

end
