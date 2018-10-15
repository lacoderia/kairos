class KairosMailer < ActionMailer::Base
  default from: "\"Futura Network\" <admin@futuranetwork.com>", reply_to: "Futura Network <admin@futuranetwork.com>" 

  def send_invitation user, invitation
    @sender = user.first_name
    @recipient = invitation.recipient_name
    @token = invitation.token
    mail(to: invitation.recipient_email, subject: "Te invitamos a registrarte a Futura Network")
  end

end
