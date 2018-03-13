class AdminAbility
  include CanCan::Ability

  def initialize(admin_user)
    can :manage, :all
  end
  
end
