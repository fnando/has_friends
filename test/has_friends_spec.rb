require "spec_helper"

# unset models used for testing purposes
Object.unset_class('User')

class User < ActiveRecord::Base
  has_many :friendships, :dependent => :destroy
  has_friends
end

describe "has_friends" do
  fixtures :users
  
  before(:each) do
    @now = Time.now
    @friendships = []
    @user = User.create(:name => 'John')
  end
  
  it "should have friends association" do
    lambda { @homer.friends }.should_not raise_error
  end
  
  it "should have friendships association" do
    lambda { @homer.friendships }.should_not raise_error
  end
  
  it "should have requested_friendships association" do
    lambda { @homer.requested_friendships }.should_not raise_error
  end
  
  it "should have pending_friendships association" do
    lambda { @homer.pending_friendships }.should_not raise_error
  end
  
  it "should have accepted_friendships association" do
    lambda { @homer.accepted_friendships }.should_not raise_error
  end
  
  it "should have denied_friendships association" do
    lambda { @homer.denied_friendships }.should_not raise_error
  end
  
  it "homer should request friendship with bart" do
    lambda do
      create_friendship_between(:homer, :bart)
      @homer.friendship_status_for(@bart).should == :pending
    end.should change(Friendship, :count).by(1)
  end
  
  it "bart should accept homer friendship requesting" do
    create_friendship_between(:homer, :bart)
    @homer.accept_friendship_with(@bart)
    @homer.should be_friend_with(@bart)
  end
  
  it "bart should deny homer friendship requesting" do
    create_friendship_between(:homer, :bart)
    @bart.deny_friendship_with(@homer)
    @bart.friendship_status_for(@homer).should == :denied
  end
  
  it "bart should automatically be friend with homer if homer has added him first" do
    create_friendship_between(:homer, :bart)
    create_friendship_between(:bart, :homer)
    
    @homer.should be_friend_with(@bart)
  end
  
  it "should remove friendship between homer and bart" do
    create_friendship_between(:homer, :bart)
    
    @homer.remove_friendship_with(@bart)
    @homer.friendship_for(@bart).should be_nil
  end
  
  it "should not remove an inexistent friendship between homer and bart" do
    @homer.remove_friendship_with(@bart).should be_false
  end
  
  it "should set requested_at when adding an user as friend" do
    Time.should_receive(:now).at_least(:once).and_return(@now)
    friendship = create_friendship_between(:homer, :bart)
    friendship.requested_at.to_s(:db).should == @now.to_s(:db)
  end
  
  it "should set accepted_at when accepting a friendship" do
    Time.should_receive(:now).at_least(:once).and_return(@now)
    friendship = create_friendship_between(:homer, :bart)
    @homer.accept_friendship_with(@bart)
    friendship.reload
    friendship.accepted_at.to_s(:db).should == @now.to_s(:db)
  end
  
  it "should set denied_at when denying a friendship" do
    Time.should_receive(:now).at_least(:once).and_return(@now)
    friendship = create_friendship_between(:homer, :bart)
    @homer.deny_friendship_with(@bart)
    friendship.reload
    friendship.denied_at.to_s(:db).should == @now.to_s(:db)
  end
  
  it "homer should get requested friendships from moe and bart" do
    @friendships << create_friendship_between(:moe, :homer)
    @friendships << create_friendship_between(:bart, :homer)
  
    @homer.requested_friendships.should == @friendships
  end
  
  it "homer should get pending friendships" do
    @friendships << create_friendship_between(:moe, :homer)
    @friendships << create_friendship_between(:bart, :homer)
  
    @homer.requested_friendships.should == @friendships
  end
  
  it "homer should get denied friendships" do
    @friendships << create_friendship_between(:homer, :moe)
    @friendships << create_friendship_between(:homer, :bart)
    
    @friendships.each(&:deny!).each(&:reload)
    
    @homer.denied_friendships.should == @friendships
  end
  
  it "homer should get accepted friendships" do
    @friendships << create_friendship_between(:homer, :moe)
    @friendships << create_friendship_between(:homer, :bart)
    
    @friendships.each(&:accept!).each(&:reload)
    
    @homer.accepted_friendships.should == @friendships
  end
  
  it "homer should get all his friends" do
    @friendships << create_friendship_between(:homer, :moe)
    @friendships << create_friendship_between(:homer, :bart)
    
    @friendships.each(&:accept!)
    @homer.friends.should == [@bart, @moe]
  end
  
  it "should not add yourself as friend" do
    create_friendship_between(:homer, :homer).should_not be_valid
  end
  
  it "should require friend" do
    lambda do
      friendship = @homer.be_friend_with(nil)
      friendship.errors.on(:friend).should_not be_nil
    end.should_not change(Friendship, :count)
  end
  
  it "should get common friends between homer and moe" do
    @friendships << create_friendship_between(:homer, :moe)
    @friendships << create_friendship_between(:homer, :burns)
    @friendships << create_friendship_between(:bart, :moe)
    
    @friendships.each(&:accept!)
    
    @homer.mutual_friends(@bart).should == [@moe]
  end
  
  it "should get people homer may know by his connection with moe" do
    @friendships << create_friendship_between(:homer, :moe)
    @friendships << create_friendship_between(:homer, :burns)
    @friendships << create_friendship_between(:bart, :moe)
    
    @friendships.each(&:accept!)
    @homer.possible_friends(@bart).should == [@burns]
  end
  
  describe "friends_count" do
    it "should be incremented using accept_friendship_with" do
      @user.be_friend_with(@homer)
      @homer.accept_friendship_with(@user)
      
      @user.reload
      @homer.reload
      
      @user.friends_count.should == 1
      @homer.friends_count.should == 1
    end
    
    it "should be incremented using be_friend_with" do
      @user.be_friend_with(@homer)
      @homer.be_friend_with(@user)
      
      @user.reload
      @homer.reload
      
      @user.friends_count.should == 1
      @homer.friends_count.should == 1
    end
    
    it "should be decremented when removing a friendship" do
      @user.be_friend_with(@homer)
      @homer.be_friend_with(@user)
      
      @user.remove_friendship_with(@homer)
      
      @user.reload
      @homer.reload
      
      @user.friends_count.should == 0
      @homer.friends_count.should == 0
    end
    
    it "should be decremented when removing a friendship using destroy method" do
      @user.be_friend_with(@homer)
      friendship = @homer.be_friend_with(@user)
      
      friendship.destroy
      
      @user.reload
      @homer.reload
      
      @user.friends_count.should == 0
      @homer.friends_count.should == 0
    end
  end
  
  describe "friends#paginate" do
    before(:each) do
      User.destroy_all
      @user = User.create(:name => 'John')
      
      (1..35).each do |i|
        @another_user = User.create(:name => "User #{i}")
        @user.be_friend_with(@another_user)
        friendship = @another_user.accept_friendship_with(@user)
        
        @user.reload
        @another_user.reload
      end
    end
    
    it "should count" do
      @user.friends.count.should == 35
    end
    
    it "should use defaults" do
      @friends = @user.friends.paginate
      @friends.size.should == 10
      @friends.should == do_query
    end
    
    it "should use custom page" do
      @friends = @user.friends.paginate(:page => 3)
      @friends.should == do_query(:offset => 20)
    end
    
    it "should use custom size" do
      @friends = @user.friends.paginate(:per_page => 3)
      @friends.should == do_query(:limit => 3)
    end
    
    it "should use custom page and size" do
      @friends = @user.friends.paginate(:page => 2, :per_page => 3)
      @friends.should == do_query(:offset => 3, :limit => 3)
    end
    
    it "should return the number of pages" do
      @friends = @user.friends.paginate(:per_page => 5)
      @friends.page_count.should == 7
      
      @friends = @user.friends.paginate(:per_page => 1)
      @friends.page_count.should == 35
      
      @friends = @user.friends.paginate(:per_page => 34)
      @friends.page_count.should == 2
    end
    
    it "should return the number of entries" do
      @friends = @user.friends.paginate
      @friends.total_entries.should == 35
    end
    
    it "should return the number of items per page" do
      @friends = @user.friends.paginate(:per_page => 3)
      @friends.per_page.should == 3
    end
    
    private
      def do_query(options={})
        User.all({
          :limit => 10, 
          :offset => 0, 
          :order => "name asc", 
          :conditions => ["id <> ?", @user]
        }.merge(options))
      end
  end
  
  describe Friendship do
    it "should create friendship" do
      lambda do
        friendship = create_friendship
        friendship.should be_valid
      end.should change(Friendship, :count).by(1)
    end
    
    it "should require status" do
      lambda do
        friendship = create_friendship(:status => nil)
        friendship.errors.on(:status).should_not be_nil
      end.should_not change(Friendship, :count)
    end
    
    it "should require valid status" do
      lambda do
        friendship = create_friendship(:status => "invalid")
        friendship.errors.on(:status).should_not be_nil
      end.should_not change(Friendship, :count)
    end
    
    it "should set requested_at when creating friendship with status equals to pending" do
      Time.should_receive(:now).at_least(:once).and_return(@now)
      friendship = create_friendship(:status => "pending")
      friendship.requested_at.to_s(:db).should == @now.to_s(:db)
    end
    
    it "should set accepted_at when creating friendship with status equals to accepted" do
      Time.should_receive(:now).at_least(:once).and_return(@now)
      friendship = create_friendship(:status => "accepted")
      friendship.accepted_at.to_s(:db).should == @now.to_s(:db)
    end
    
    it "should set denied_at when creating friendship with status equals to denied" do
      Time.should_receive(:now).at_least(:once).and_return(@now)
      friendship = create_friendship(:status => "denied")
      friendship.denied_at.to_s(:db).should == @now.to_s(:db)
    end
    
    it "homer should be detected as the guy who started the friendship" do
      friendship = create_friendship_between(:homer, :moe)
      friendship.should be_requested_by(@homer)
    end
    
    it "should mark friendship as accepted" do
      friendship = create_friendship(:status => 'pending')
      friendship.accept!.should be_true
      friendship.status.should == 'accepted'
    end
    
    it "should mark friendship as denied" do
      friendship = create_friendship(:status => 'pending')
      friendship.deny!.should be_true
      friendship.status.should == 'denied'
    end
    
    it "should request friendship only once when users are friends" do
      lambda {
        friendship = create_friendship_between(:homer, :bart)
        friendship.accept!
        create_friendship_between(:homer, :bart)
      }.should change(Friendship, :count).by(1)
    end
  end
  
  private
    def create_friendship_between(from, to)
      users(from).be_friend_with(users(to))
    end
    
    def create_friendship(options={})
      Friendship.create({
        :user => users(:homer),
        :friend => users(:bart),
        :status => 'pending'
      }.merge(options))
    end
end