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

end
