class Card < ApplicationRecord
  belongs_to :user

  scope :prana, -> {where(company: 'PRANA').order(id: :asc)} 
  scope :omein, -> {where(company: 'OMEIN').order(id: :asc)}

  def self.create_for_user user, token, device_session, company

    company = OpenpayHelper.validate_company(company)
    payment_api = OpenpayHelper.new(company)
    user_openpay_id = user.get_openpay_id(company)

    card_openpay_hash = payment_api.add_card user_openpay_id, token, device_session
    
    primary = false
    if user.cards.method(company.downcase).call.empty?
      primary = true
    end

    card = Card.create!(user: user, openpay_id: card_openpay_hash["id"], active: true, primary: primary, company: company, 
                        holder_name: card_openpay_hash["holder_name"], card_number: card_openpay_hash["card_number"],
                        expiration: "#{card_openpay_hash["expiration_month"]}/#{card_openpay_hash["expiration_year"]}",
                        brand: card_openpay_hash["brand"], is_bank_account: card_openpay_hash["allows_payouts"])
    return card
  end

  def self.delete_for_user user, card_id, company

    company = OpenpayHelper.validate_company(company)
    if user.cards.method(company.downcase).call.size == 1
      raise "Necesitas tener al menos una tarjeta"
    end
    
    payment_api = OpenpayHelper.new(company)
    user_openpay_id = user.get_openpay_id(company)
    card = Card.find(card_id)

    is_primary_card = card.primary
    payment_api.delete_card user_openpay_id, card.openpay_id
    card.destroy

    if is_primary_card
      user.cards.method(company.downcase).call.first.update_attribute("primary", true)
    end

    return user.cards.method(company.downcase).call
  end

  def self.set_primary_for_user user, card_id, company
    company = OpenpayHelper.validate_company(company)
    user_card = Card.find(card_id)
    Card.where("user_id = ?", user.id).method(company.downcase).call.update_all(primary: false)
    user_card.update_attribute(:primary, true)
    return user_card
  end

  def self.get_all_for_user user, company
    company = OpenpayHelper.validate_company(company)
    return user.cards.method(company.downcase).call
  end
 
end

