class Ability
  include CanCan::Ability

  def initialize(user)

    #Cualquiera no loggeado
    cannot :manage, :all

    can :create, :registration
    can [:create, :update], :password
    can [:create, :get, :destroy], :session
    can [:by_external_id, :confirm], User
    #can [:create, :update], :password

    if user.instance_of? User

      can :manage, User, id: user.id
      can :manage, Invitation, user_id: user.id
      can :manage, ShippingAddress, ShippingAddress.joins(:users).where("shipping_addresses_users.user_id = ?", user.id) do |shipping_address|
        if shipping_address.id
          shipping_address.users.first.id == user.id
        else
          true
        end
      end
      
    end

  end
  
end
