class Ability
  include CanCan::Ability

  def initialize(user)

    #Cualquiera no loggeado
    cannot :manage, :all

    can :create, :registration
    can [:create, :get, :destroy], :session
    #can [:create, :update], :password

    if user.instance_of? User

      can :manage, User, id: user.id

    end

  end
  
end
