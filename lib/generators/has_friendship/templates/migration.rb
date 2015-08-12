class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships do |t|
      t.references :friendable, polymorphic: true
      t.integer  :friend_id
      t.integer  :friend_issuer_id
      t.integer  :user_requester_id
      t.integer  :user_replier_id
      t.integer  :user_remover_id
      t.string   :status
      t.string   :connection_type
      t.datetime :removed_at
      
      t.timestamps
    end
  end

end