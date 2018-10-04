class InvitationsController < ApiController
  
  load_and_authorize_resource
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

  def by_user
    begin
      @user = User.find(current_user.id)
      @invitations = @user.invitations
      render json: @invitations
    rescue Exception => e
      @invitation = Invitation.new
      @invitation.errors.add(:error_finding_invitations, e.message)
      render json: ErrorSerializer.serialize(@invitation.errors), status: 500
    end

  end

  private

    def invitation_params
      params.require(:invitation).permit(:user_id, :recipient_name, :recipient_email, :token, :used)
    end
  
end
