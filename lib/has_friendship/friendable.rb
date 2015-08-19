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
                                             friend_id: friend.id, status: 'pending', connection_type: options[:connection_type],
                                             friend_issuer_id:self.id, user_requester_id: options[:user_requester_id])
            HasFriendship::Friendship.create(friendable_id: friend.id, friendable_type: friend.class.base_class.name,
                                             friend_id: self.id, status: 'requested', connection_type: options[:connection_type],
                                             friend_issuer_id:self.id, user_requester_id: options[:user_requester_id])
          end
        end
      end

      def accept_request(friend, options = {})
        if HasFriendship::Friendship.find_friendship(self, friend, 'requested')
          transaction do
            pending_friendship = HasFriendship::Friendship.find_friendship(friend, self, 'pending')
            pending_friendship.status = 'accepted'
            pending_friendship.friend_issuer_id = self.id
            pending_friendship.user_replier_id = options[:user_replier_id]
            pending_friendship.save

            requeseted_friendship = HasFriendship::Friendship.find_friendship(self, friend, 'requested')
            requeseted_friendship.user_replier_id = options[:user_replier_id]
            requeseted_friendship.status = 'accepted'
            requeseted_friendship.friend_issuer_id = self.id
            requeseted_friendship.save
            requeseted_friendship
          end
        end
      end

      def decline_request(friend, options = {})
        if HasFriendship::Friendship.find_friendship(self, friend, 'requested')
          transaction do
            pending_friendship = HasFriendship::Friendship.find_friendship(friend, self, 'pending')
            pending_friendship.status = 'declined'
            pending_friendship.friend_issuer_id = self.id
            pending_friendship.user_replier_id = options[:user_replier_id]
            pending_friendship.save

            requeseted_friendship = HasFriendship::Friendship.find_friendship(self, friend, 'requested')
            requeseted_friendship.user_replier_id = options[:user_replier_id]
            requeseted_friendship.status = 'declined'
            requeseted_friendship.friend_issuer_id = self.id
            requeseted_friendship.save
          end
        end
      end

      def remove_friend(friend, options = {})
        if HasFriendship::Friendship.find_friendship(self, friend, ['pending', 'accepted'])
          transaction do
            pending_friendship = HasFriendship::Friendship.find_friendship(self, friend, ['pending', 'accepted'])
            pending_friendship.status = 'deleted'
            pending_friendship.user_remover_id = options[:user_remover_id]
            pending_friendship.removed_at = Time.now
            pending_friendship.friend_issuer_id = self.id
            pending_friendship.save

            requeseted_friendship = HasFriendship::Friendship.find_friendship(friend, self, ['requested', 'accepted'])
            requeseted_friendship.user_remover_id = options[:user_remover_id]
            requeseted_friendship.removed_at = Time.now
            requeseted_friendship.status = 'deleted'
            requeseted_friendship.friend_issuer_id = self.id
            requeseted_friendship.save
          end
        end
      end

      def friends_with?(friend)
        HasFriendship::Friendship.where(friendable_id: self.id, friend_id: friend.id, status: 'accepted').present?
      end

      def friends_with_connetion_type(connection_type)
        self.class.where(id: HasFriendship::Friendship.where(friendable_id: self.id, connection_type: connection_type, status: 'accepted').pluck(:friend_id))
      end

      def friends_with_requester(requester_id)
        self.class.where(id: HasFriendship::Friendship.where(friendable_id: self.id, requester_id: requester_id, status: 'accepted').pluck(:friend_id))
      end

      def friends_with_approver(approver_id)
        self.class.where(id: HasFriendship::Friendship.where(friendable_id: self.id,  approver_id: approver_id, status: 'accepted').pluck(:friend_id))
      end

      def friends_status_connections(status)
        HasFriendship::Friendship.where(friendable_id: self.id,  status: status)
      end

      def suggestions_with_second_degree(connection_type)
        my_friends_ids = self.friends_with_connetion_type(connection_type).uniq.pluck(:id)
        friends_of_my_friends = HasFriendship::Friendship.where(friendable_id: my_friends_ids,  status: 'accepted').uniq.pluck(:friend_id)
        suggestions_ids =  (my_friends_ids - friends_of_my_friends) | (friends_of_my_friends - my_friends_ids)
        suggestions_ids.delete_if{|c| c == self.id || my_friends_ids.include?(c)}
        self.class.where(id: suggestions_ids)
      end

      def shared_connections(friend, connection_type='contact')
        my_friends_ids = self.friends_with_connetion_type(connection_type).uniq.pluck(:id)
        friends_of_my_friend = friend.friends_with_connetion_type(connection_type).uniq.pluck(:id)
        common_friend_ids =  my_friends_ids & friends_of_my_friend
        common_friend_ids.delete_if{|c| c == self.id || c == friend.id}
        self.class.where(id: common_friend_ids)
      end
    end
  end
end
