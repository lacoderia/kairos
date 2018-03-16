class InvitationsController < ApiController
  include ErrorSerializer
  
  before_action :authenticate_user!

  def create
    begin
      @invitation = Invitation.new(invitation_params)
      @invitation.generate_invitation
      render json: @invitation 
    rescue Exception => e
      @invitation = Invitation.new
      @invitation.errors.add(:error_creating_invitation, e.message)
      render json: ErrorSerializer.serialize(@invitation.errors), status: 500
    end
  end

  private

    def invitation_params
      params.require(:invitation).permit(:user_id, :recipient_name, :recipient_email, :token, :used)
    end
  
end
