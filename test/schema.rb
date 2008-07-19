ActiveRecord::Schema.define(:version => 0) do
  create_table :users do |t|
    t.string :name
    t.integer :friends_count, :null => false, :default => 0
  end
  
  create_table :friendships do |t|
    t.references :user, :friend
    t.datetime :requested_at, :accepted_at, :denied_at, :null => true, :default => nil
    t.string :status
  end
end