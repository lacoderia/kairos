class Ability
  include CanCan::Ability

  def initialize(user)

    #Cualquiera no loggeado
    cannot :manage, :all

    can :create, :registration
    can [:create, :update], :password
    can [:create, :get, :destroy], :session
    can [:by_external_id, :confirm], User
    can :get_device_session_id, Card    

    if user.instance_of? User

      can :manage, User, id: user.id
      #TODO: check that a user can get summaries only for downlines, not for uplines
      can :manage, Summary
      can :by_company, Item
      can :manage, Invitation, user_id: user.id
      can :manage, Card, user_id: user.id      
      can [:create, :update, :deactivate], ShippingAddress, user.shipping_addresses do |shipping_address|
        if shipping_address.id
          shipping_address.users.first.id == user.id
        else
          true
        end
      end
      can [:get_all_for_user], ShippingAddress, users: [user]   
      can :manage, Order, users: [user]
    end

  end
  
end
