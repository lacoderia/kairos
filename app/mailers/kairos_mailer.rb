class KairosMailer < ActionMailer::Base
  default from: "\"Prana\" <contacto@prana.mx>", reply_to: "Prana <contacto@prana.mx>" 

  def send_invitation user, invitation
    @sender = user.first_name
    @recipient = invitation.recipient_name
    @token = invitation.token
    mail(to: invitation.recipient_email, subject: "Te invitamos a registrarte a Prana")
  end

end
