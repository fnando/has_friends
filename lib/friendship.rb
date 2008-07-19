class Friendship < ActiveRecord::Base
  # constants
  MESSAGES = {
    :user_is_required => "is required",
    :friend_is_required => "is required"
  }
  
  STATUSES = %w(pending accepted denied)
  
  # associations
  belongs_to :user
  belongs_to :friend, :class_name => "User", :foreign_key => "friend_id"
  
  # validations
  validates_presence_of :user_id, :user,
    :message => MESSAGES[:user_is_required]
  
  validates_presence_of :friend_id, :friend,
    :message => MESSAGES[:friend_is_required]
  
  validates_inclusion_of :status,
    :in => STATUSES
  
  validate :should_not_add_yourself_as_friend
  
  # callbacks
  before_save :ensure_date_is_set_according_to_status
  before_destroy :decrement_friends_counter
  
  def accept!
    write_attribute(:status, 'accepted')
    write_attribute(:accepted_at, Time.now)
    
    increment_friends_counter
    
    save(false)
  end
  
  def deny!
    write_attribute(:status, 'denied')
    write_attribute(:denied_at, Time.now)
    save(false)
  end
  
  def pending!
    write_attribute(:status, 'pending')
    write_attribute(:pending_at, nil)
    save(false)
  end
  
  def requested_by?(u)
    user == u
  end
  
  private
    def should_not_add_yourself_as_friend
      errors.add(:friend, 'should not be you') if user && friend && friend_id == user_id
    end
    
    def ensure_date_is_set_according_to_status
      write_attribute(:requested_at, Time.now) if status == 'pending' && requested_at.blank?
      write_attribute(:denied_at, Time.now) if status == 'denied' && denied_at.blank?
      write_attribute(:accepted_at, Time.now) if status == 'accepted' && accepted_at.blank?
    end
    
    def increment_friends_counter
      [friend, user].each do |u|
        u.friends_count += 1
        u.save(false)
      end
    end
    
    def decrement_friends_counter
      [friend, user].each do |u|
        u.friends_count -= 1
        u.save(false)
      end
    end
end