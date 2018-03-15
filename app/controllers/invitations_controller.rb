class InvitationsController < ApiController
  include ErrorSerializer
  
  before_action :authenticate_user!

  def create
    begin
      @invitation = Invitation.new(invitation_params)
      @invitation.generate_invitation
      render @invitation 
    rescue Exception => e
      render json: ErrorSerializer.serialize(@invitation.errors)
    end
  end

  private

    def invitation_params
      params.require(:invitation).permit(:user_id, :recipient_name, :recipient_email, :token, :used)
    end
  
end
