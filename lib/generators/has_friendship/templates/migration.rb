class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships do |t|
      t.references :friendable, polymorphic: true
      t.integer  :friend_id
      t.integer  :requester_id
      t.integer  :approver_id
      t.string   :status
      t.string   :connection_type
      
      t.timestamps
    end
  end

end