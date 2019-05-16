class KairosMailer < ActionMailer::Base
  default from: "\"Futura Network\" <admin@futuranetwork.com>", reply_to: "Futura Network <admin@futuranetwork.com>" 

  def send_invitation user, invitation
    @sender = user.first_name
    @recipient = invitation.recipient_name
    @token = invitation.token
    mail(to: invitation.recipient_email, subject: "Te invitamos a registrarte a Futura Network")
  end

  def send_summary user, data
    @user = user
    @filepath = data[:filepath]
    @month = data[:month]
    attachments["#{@user.external_id}_#{@month}.csv"] = File.read(@filepath)
    mail(to: @user.email, subject: "Tu reporte de FuturaNetwork del mes de #{@month}")
  end

  def order user, order 
    @user = user
    @order = order
    mail(to: @user.email, subject: "Futura Network: confirmación de orden #{@order.order_number}")
  end

  def process_order user, order
    @user = user
    @order = order
    mail(to: Config.order_notification_email, subject: "Nuevo pedido en línea #{@order.company} - #{@order.order_number}")
  end

  def send_weekly_commissions filepath, period
    attachments[filepath] = File.read(filepath)
    mail(to: "benjamin@coderia.mx, ricardo@coderia.mx, victor@omein.com", subject: "Comisiones de Futuranetwork semanales de #{period}")
  end

  def send_unilevel_commissions_prana filepath, period 
    attachments[filepath] = File.read(filepath)
    mail(to: "benjamin@coderia.mx, ricardo@coderia.mx, victor@omein.com", subject: "Comisiones de Futuranetwork unilevel de PRANA #{period}")
  end

  def send_unilevel_commissions_omein filepath, period
    attachments[filepath] = File.read(filepath)
    mail(to: "benjamin@coderia.mx, ricardo@coderia.mx, victor@omein.com", subject: "Comisiones de Futuranetwork unilevel de OMEIN #{period}")
  end

end
