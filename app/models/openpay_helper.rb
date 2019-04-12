class OpenpayHelper 
  
  def initialize(company)
    if company == PranaCompPlan::COMPANY_PRANA
      @openpay = OpenpayApi.new(Rails.application.secrets.prana_openpay_merchant_id, Rails.application.secrets.prana_openpay_private_key)
    elsif company == OmeinCompPlan::COMPANY_OMEIN
      @openpay = OpenpayApi.new(Rails.application.secrets.omein_openpay_merchant_id, Rails.application.secrets.omein_openpay_private_key)
    else
      raise "Incorrect company name"
    end
  end

  # Crea un usuario en Openpay
  # Recibe:
  # user - un objeto User
  # Regresa el ID de openpay 
  def create_user user
    begin
      customers = @openpay.create(:customers)
      customer_hash = {
        #external_id: user.id,
        name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        requires_account: true,
      }
      result_hash = customers.create(customer_hash)
      if result_hash["error_code"]
        raise result_hash["error_code"] 
      else
        return result_hash["id"]
      end
    rescue Exception => e
      raise "Error creando usuario en Openpay - #{e.message}"
    end
  end

  # Registra una tarjeta a un usuario
  # Recibe:
  # user_openpay_id - el id de openpay del usuario
  # card_token_id - el token de la tarjeta de crédito/débito
  # device_session_id - el id generado para detección antifraude
  # Regresa el ID de la tarjeta registrada
  def add_card user_openpay_id, token_id, device_session_id
    begin
      cards = @openpay.create(:cards)
      card_hash = {
        token_id: token_id,
        device_session_id: device_session_id
      }
      result_hash = cards.create(card_hash, user_openpay_id)
      if result_hash["error_code"]
        raise result_hash["error_code"] 
      else
        return result_hash
      end
    rescue Exception => e
      raise "Error creando tarjeta. Por favor verifica que los datos son correctos."
    end
  end

  # Registra una cuenta bancaria a un usuario
  # Recibe:
  # user_openpay_id - el id de openpay del usuario
  # clabe - la clabe de la cuenta
  # holder_name - el nombre del titular de la cuenta
  # Regresa el id de la cuenta
  def add_account user_openpay_id, clabe, holder_name
    begin
      accounts = @openpay.create(:bankaccounts)
      account_hash = {
        holder_name: holder_name,
        alias: "Cuenta bancaria",
        clabe: clabe
      }
      result_hash = accounts.create(account_hash, user_openpay_id)
      if result_hash["error_code"]
        raise result_hash["error_code"] 
      else
        return result_hash
      end
    rescue Exception => e 
      raise "Error creando cuenta CLABE. Por favor verifica que los datos son correctos."
    end
  end

  # Obtiene la información de una tarjeta en Openpay
  # Recibe:
  # card_id - el id de Openpay de la tarjeta
  # user_openpay_id - el id de Openpay del usuario
  # Regresa el objeto de la tarjeta 
  def get_card card_id, user_openpay_id
    begin
      cards = @openpay.create(:cards)
      result_hash = cards.get(card_id, user_openpay_id)
      if result_hash["error_code"]
        raise result_hash["error_code"] 
      else
        return result_hash
      end
    rescue Exception => e
      raise "Error obteniendo la tarjeta de Openpay - #{e.message}"
    end
  end

  # Obtiene la información de una cuenta bancaria en Openpay
  # Recibe:
  # account_id - el id de Openpay de la cuenta bancaria
  # user_openpay_id - el id de Openpay del usuario
  # Regresa el objeto con la información de la cuenta bancaria
  def get_bank_account account_id, user_openpay_id
    begin
      accounts = @openpay.create(:bankaccounts)
      result_hash = accounts.get(user_openpay_id, account_id)
      if result_hash["error_code"]
        raise result_hash["error_code"] 
      else
        return result_hash
      end
    rescue Exception => e
      raise "Error obteniendo la cuenta bancaria de Openpay - #{e.message}"
    end
  end

  # Borra una tarjeta en Openpay
  # Recibe:
  # card_id - el id de Openpay de la tarjeta
  # user_openpay_id - el id de Openpay del usuario
  # Regresa nada si la tarjeta fue borrada
  def delete_card user_openpay_id, card_id 
    begin
      cards = @openpay.create(:cards)
      result_hash = cards.delete(card_id, user_openpay_id)
      if result_hash 
        raise "Error borrando la tarjeta en Openpay" 
      else
        return true 
      end
    rescue Exception => e
      raise "Error borrando la tarjeta de Openpay - #{e.message}"
    end
  end

  # Borra una cuenta bancaria en Openpay
  # Recibe:
  # account_id - el id de Openpay de la cuenta bancaria
  # user_openpay_id - el id de Openpay del usuario
  # Regresa nada si la cuenta fue borrada
  def delete_bank_account user_openpay_id, account_id
    begin
      accounts = @openpay.create(:bankaccounts)
      result_hash = accounts.delete(user_openpay_id, account_id)
      if result_hash
        raise "Error borrando la cuenta de banco en Openpay"
      else
        return true 
      end
    rescue Exception => e
      raise "Error borrando la cuenta bancaria de Openpay - #{e.message}"
    end
  end
  
  # Obtiene el saldo de una cuenta de Openpay
  # Recibe:
  # user_openpay_id - el id de Openpay de la cuenta bancaria
  # Regresa el saldo de la cuenta
  def get_user user_openpay_id
    begin
      customers = @openpay.create(:customers)
      result_hash = customers.get(user_openpay_id)
      if result_hash["error_code"]
        raise result_hash["error_code"] 
      else
        return result_hash
      end
    rescue Exception => e
      raise "Error obteniendo saldo de Openpay - #{e.message}"
    end
  end

  # Realiza cargo a la tarjeta 
  # Recibe: 
  # user_openpay_id - el id de openpay del usuario 
  # card_id - el id de openpay de la tarjeta del usuario 
  # amount - la cantidad a cobrar
  # ticket - el ticket de la orden
  # description - la descripción de la operación
  # device_session_id - el id generado para detección antifraude
  # Regresa el objeto de cargo
  def charge user_openpay_id, card_id, amount, order_id, description, device_session_id
    begin
      charges = @openpay.create(:charges)
      request_hash = {
        method: "card",
        source_id: card_id,
        amount: amount,
        description: description,
        #order_id: order_id, 
        device_session_id: device_session_id
      }
      result_hash = charges.create(request_hash, user_openpay_id)
      if result_hash["error_code"]
        raise result_hash["error_code"] 
      else
        return result_hash
      end
    rescue Exception => e
      raise "Error realizando un cargo en Openpay - #{e.message}"
    end
  end

  # Cobra comisión desde el balance del usuario 
  # Recibe:
  # user_openpay_id - el id de openpay del usuario
  # amount - el monto a cobrar
  # description - la descripción de la operación
  # ticket - el ticket de la orden
  # Regresa el objeto de cargo
  def charge_fee user_openpay_id, amount, description, order_id 
    begin
      fees = @openpay.create(:fees)
      request_hash = {
        customer_id: user_openpay_id,
        amount: amount,
        description: description,
        #order_id: order_id
      }
      result_hash = fees.create(request_hash)
      if result_hash["error_code"]
        raise result_hash["error_code"] 
      else
        return result_hash
      end
    rescue Exception => e
      raise "Error realizando un cargo de comisión en Openpay - #{e.message}"
    end
  end
  
  # Transfiere fondos a la cuenta de banco del usuario
  # Recibe:
  # user_openpay_id - el id de openpay del usuario 
  # amount - el monto a transferir
  # description - la descripción de la operación
  # Regresa el objeto de la transferencia 
  def payout user_openpay_id, account_id, amount, description 
    begin
      payouts = @openpay.create(:payouts)
      request_hash = {
        method: "bank_account",
        destination_id: account_id,
        amount: amount,
        description: description
      }
      result_hash = payouts.create(request_hash, user_openpay_id)
      if result_hash["error_code"]
        raise result_hash["error_code"] 
      else
        return result_hash
      end
    rescue Exception => e
      raise "Error realizando un depósito en Openpay - #{e.message}"
    end
  end

  def self.validate_company company
    company.upcase!

    if [OmeinCompPlan::COMPANY_OMEIN, PranaCompPlan::COMPANY_PRANA].include?(company)
      return company  
    else
      raise 'Invalid company name'
    end
  end

end

