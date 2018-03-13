class NboxMailer < ActionMailer::Base
  default from: "\"Prana\" <contacto@prana.mx>", reply_to: "Prana <contacto@prana.mx>" 

  def welcome user, data = nil
    @user = user
    mail(to: @user.email, subject: "¡Bienvenido a Prana!")
  end

end
