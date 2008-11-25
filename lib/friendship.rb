class Friendship < ActiveRecord::Base
  # constants
  STATUS_ALREADY_FRIENDS     = 1
  STATUS_ALREADY_REQUESTED   = 2
  STATUS_IS_YOU              = 3
  STATUS_FRIEND_IS_REQUIRED  = 4
  STATUS_FRIENDSHIP_ACCEPTED = 5
  STATUS_REQUESTED           = 6
  
  # scopes
  named_scope :pending, :conditions => {:status => 'pending'}
  named_scope :accepted, :conditions => {:status => 'accepted'}
  named_scope :requested, :conditions => {:status => 'requested'}
  
  # associations
  belongs_to :user
  belongs_to :friend, :class_name => 'User', :foreign_key => 'friend_id'
  
  # callback
  after_destroy do |f|
    User.decrement_counter(:friends_count, f.user_id)
  end
  
  def pending?
    status == 'pending'
  end
  
  def accepted?
    status == 'accepted'
  end
  
  def requested?
    status == 'requested'
  end

  def accept!
    User.increment_counter(:friends_count, user.id) unless accepted?
    update_attribute(:status, 'accepted')
  end
end