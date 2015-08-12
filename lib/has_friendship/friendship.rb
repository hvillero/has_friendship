module HasFriendship
  class Friendship < ActiveRecord::Base

    def self.check_one_side(friendable, friend)
      find_by(friendable_id: friendable.id, friendable_type: friendable.class.base_class.name, friend_id: friend.id).present?
    end

    def self.delete_one_side(friendable, friend)
      find_by(friendable_id: friendable.id, friendable_type: friendable.class.base_class.name, friend_id: friend.id).destroy
      false
    end

    def self.check_not_declined_or_deleted(friendable, friend)
      if find_by(friendable_id: friendable.id, friendable_type: friendable.class.base_class.name, friend_issuer_id: friendable.id,
                 friend_id: friend.id, status: ['declined', 'deleted']).present?
        delete_one_side(friendable, friend)
        delete_one_side(friend, friendable)
        false
      else
        true
      end
    end

    def self.exist?(friendable, friend)
      if check_one_side(friendable, friend) && check_one_side(friend, friendable)
        check_not_declined_or_deleted(friendable, friend)
      elsif check_one_side(friendable, friend)
        delete_one_side(friendable, friend)
      elsif check_one_side(friend, friendable)
        delete_one_side(friend,friendable)
      end
    end

    def self.find_friendship(friendable, friend, status)
      find_by(friendable_id: friendable.id, friendable_type: friendable.class.base_class.name, friend_id: friend.id, status: status)
    end
  end
end
