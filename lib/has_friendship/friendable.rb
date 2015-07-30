module HasFriendship
  module Friendable

    def friendable?
      false
    end

    def has_friendship

      class_eval do
        has_many :friendships, as: :friendable, class_name: "HasFriendship::Friendship", dependent: :destroy
        has_many :friends,
                  -> { where friendships: { status: 'accepted' } },
                  through: :friendships

        has_many :requested_friends,
                  -> { where friendships: { status: 'requested' } },
                  through: :friendships,
                  source: :friend

        has_many :pending_friends,
                  -> { where friendships: { status: 'pending' } },
                  through: :friendships,
                  source: :friend
                  
        has_many :declined_friends,
                  -> { where friendships: { status: 'declined' } },
                  through: :friendships,
                  source: :friend

        has_many :deleted_friends,
                  -> { where friendships: { status: 'deleted' } },
                  through: :friendships,
                  source: :friend
                  
                  
        def self.friendable?
          true
        end
      end

      include HasFriendship::Friendable::InstanceMethods
      include HasFriendship::Extender
    end

    module InstanceMethods

      def friend_request(friend, options = {})
        unless self == friend || HasFriendship::Friendship.exist?(self, friend)
          transaction do
            HasFriendship::Friendship.create(friendable_id: self.id, friendable_type: self.class.base_class.name, 
                                            friend_id: friend.id, status: 'pending', connection_type: options[:connection_type], requester_id: options[:requester_id])
            HasFriendship::Friendship.create(friendable_id: friend.id, friendable_type: friend.class.base_class.name, 
                                            friend_id: self.id, status: 'requested', connection_type: options[:connection_type], requester_id: options[:requester_id])
          end
        end
      end

      def accept_request(friend, options = {})
        transaction do
          pending_friendship = HasFriendship::Friendship.find_friendship(friend, self)
          pending_friendship.status = 'accepted'
          pending_friendship.replier_id = options[:replier_id]
          pending_friendship.save

          requeseted_friendship = HasFriendship::Friendship.find_friendship(self, friend)
          requeseted_friendship.replier_id = options[:replier_id]
          requeseted_friendship.status = 'accepted'
          requeseted_friendship.save
        end
      end

      def decline_request(friend, options = {})
        transaction do
          pending_friendship = HasFriendship::Friendship.find_friendship(friend, self)
          pending_friendship.status = 'declined'
          pending_friendship.replier_id = options[:replier_id]
          pending_friendship.save

          requeseted_friendship = HasFriendship::Friendship.find_friendship(self, friend)
          requeseted_friendship.replier_id = options[:replier_id]
          requeseted_friendship.status = 'declined'
          requeseted_friendship.save
        end
                #
        #
        # transaction do
        #   HasFriendship::Friendship.find_friendship(friend, self).destroy
        #   HasFriendship::Friendship.find_friendship(self, friend).destroy
        #end
      end

      def remove_friend(friend, options = {})
        transaction do
          pending_friendship = HasFriendship::Friendship.find_friendship(friend, self)
          pending_friendship.status = 'deleted'
          pending_friendship.replier_id = options[:replier_id]
          pending_friendship.save

          requeseted_friendship = HasFriendship::Friendship.find_friendship(self, friend)
          requeseted_friendship.replier_id = options[:replier_id]
          requeseted_friendship.status = 'deleted'
          requeseted_friendship.save
        end
        # transaction do
        #   HasFriendship::Friendship.find_friendship(friend, self).destroy
        #   HasFriendship::Friendship.find_friendship(self, friend).destroy
        # end
      end

      def friends_with?(friend)
        HasFriendship::Friendship.where(friendable_id: self.id, friend_id: friend.id, status: 'accepted').present?
      end
      
      def friends_with_connetion_type(connection_type)
        self.class.where(id: HasFriendship::Friendship.where(friendable_id: self.id, connection_type: connection_type).pluck(:friendable_id))
      end
      
      def friends_with_requester(requester_id)
        self.class.where(id: HasFriendship::Friendship.where(friendable_id: self.id, requester_id: requester_id).pluck(:friendable_id))
      end
      
      def friends_with_approver(approver_id)
        self.class.where(id: HasFriendship::Friendship.where(friendable_id: self.id,  approver_id: approver_id).pluck(:friendable_id))
      end
      
      def friends_status_connections(status)
        HasFriendship::Friendship.where(friendable_id: self.id,  status: status)
      end  
    end
  end
end
