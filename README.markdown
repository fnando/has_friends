has_friends
===========

**ATTENTION:** This is a new simpler implementation. If you want to use the previous version,
get the 1.0 tag.

Instalation
-----------

1) Install the plugin with `script/plugin install git://github.com/fnando/has_friends.git`

2) Generate a migration with `script/generate migration create_friendships` and add the following code:

	class CreateFriendships < ActiveRecord::Migration
	  def self.up
	    create_table :friendships do |t|
	      t.references :user, :friend
	      t.datetime :requested_at, :accepted_at, :null => true, :default => nil
	      t.string :status
	    end
    
	    add_index :friendships, :user_id
	    add_index :friendships, :friend_id
	    add_index :friendships, :status
	  end

	  def self.down
	    drop_table :friendships
	  end
	end

3) Run the migrations with `rake db:migrate`

Usage
-----

1) Add the method call `has_friends` to your model.

	class User < ActiveRecord::Base
	  has_friends
	end

	john = User.find_by_login 'john'
	mary = User.find_by_login 'mary'
	paul = User.find_by_login 'paul'

	# john wants to be friend with mary
	# always return a friendship object
	john.be_friends_with(mary)

	# are they friends?
	john.friends?(mary)

	# get the friendship object
	john.friendship_for(mary)

	# mary accepts john's request if it exists;
	# makes a friendship request otherwise.
	mary.be_friends_with(john)

	# check if paul is mary's friend
	mary.friends?(paul)

	# check if a user is the current user, so it can
	# be differently presented
	mary.friends.each {|friend| friend.is?(current_user) }

	# if you're dealing with a friendship object,
	# the following methods are available
	friendship.accept!
	
	# if you're using has_paginate plugin, you can use it:
	mary.friends.paginate(:page => 3, :limit => 10)
	
	# the be_friends_with method returns 2 params: friendship object and status.
	# the friendship object will be present only when the friendship is created
	# (that is, when is requested for the first time)
	# STATUS_ALREADY_FRIENDS		 # => users are already friends
	# STATUS_ALREADY_REQUESTED		 # => user has already requested friendship
	# STATUS_IS_YOU					 # => user is trying add himself as friend
	# STATUS_FRIEND_IS_REQUIRED      # => friend argument is missing
	# STATUS_FRIENDSHIP_ACCEPTED     # => friendship has been accepted
	# STATUS_REQUESTED				 # => friendship has been requested
	
	friendship, status = mary.be_friends_with(john)
	
	if status == Friends::STATUS_REQUESTED
	  # the friendship has been requested
	  Mailer.deliver_friendship_request(friendship)
	elsif status == Friends::STATUS_ALREADY_FRIENDS
	  # they're already friends
	else
	  # ...
	end

NOTE: You should have a User model. You should also have a `friends_count` column
on your model. Otherwise, this won't work! You can add as following:

1) Create a new migration with `script/generate migration add_friends_count_to_user`:

	class CreateFriendships < ActiveRecord::Migration
	  def self.up
	    add_column :users, :friends_count, :integer, :default => 0, :null => false
	  end

	  def self.down
	    remove_column :users, :friends_count
	  end
	end

LICENSE:
--------

(The MIT License)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.