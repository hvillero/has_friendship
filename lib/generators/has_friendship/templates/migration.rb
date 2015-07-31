class CreateFriendships < ActiveRecord::Migration
  def change
    create_table :friendships do |t|
      t.references :friendable, polymorphic: true
      t.integer  :friend_id
      t.integer  :requester_id
      t.integer  :replier_id
      t.integer  :remover_id
      t.string   :status
      t.string   :connection_type
      t.datetime :removed_at
      
      t.timestamps
    end
  end

end