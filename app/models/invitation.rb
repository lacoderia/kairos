class Invitation < ApplicationRecord
  belongs_to :user

   def generate_invitation
    self.token = SecureRandom.urlsafe_base64
    self.save!
    SendEmailJob.perform_later("send_invitation", self.user, self)    
  end

end
