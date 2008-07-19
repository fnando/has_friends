module SimplesIdeias
  module Acts
    module Friendships
      def self.included(base)
        base.extend SimplesIdeias::Acts::Friendships::ClassMethods
      end
      
      module ClassMethods
        FRIENDS_QUERY = 'SELECT DISTINCT users.* ' +
          'FROM users, friendships ' +
          'WHERE friendships.status = "accepted" AND ' + 
          '(friendships.user_id = #{id} OR friendships.friend_id = #{id}) AND ' +
          'users.id IN(friendships.user_id, friendships.friend_id) AND ' + 
          'users.id <> #{id} ' +
          'ORDER BY users.name'
        
        def has_friends
          include SimplesIdeias::Acts::Friendships::InstanceMethods
          
          # all your friendships
          has_many :friendships
          
          # all your friends
          has_many :friends,
            :finder_sql => FRIENDS_QUERY,
            :class_name => 'User' do
              def paginate(options={})
                options[:per_page] ||= 10
                options[:page] ||= 1
                
                page = [1, options.delete(:page).to_i].max
                per_page = options.delete(:per_page).to_i
                @total_entries = proxy_owner.friends.count
                @total_pages = (@total_entries.to_f / per_page).ceil
                
                offset = (page - 1) * per_page
                
                query = FRIENDS_QUERY.dup + " LIMIT #{offset},#{per_page}"
                query.gsub! /#\{id\}/sm, proxy_owner.id.to_s
                users = User.find_by_sql [query, offset, per_page]
                
                users.instance_variable_set('@total_entries', @total_entries)
                users.instance_variable_set('@total_pages', @total_pages)
                users.instance_variable_set('@per_page', per_page)
                
                def users.total_entries
                  @total_entries
                end
                
                def users.per_page
                  @per_page
                end
                
                def users.page_count
                  @total_pages
                end
                
                users
              end
            end
          
          # return all friendships users requested
          # and you haven't accepted yet
          has_many :requested_friendships,
            :class_name => 'Friendship',
            :foreign_key => 'friend_id',
            :conditions => {:status => 'pending'}
          
          # return all friendships you requested
          # that wasn't accepted yet
          has_many :pending_friendships,
            :class_name => 'Friendship',
            :conditions => {:status => 'pending'}
          
          # return all accepted friendships you requested
          has_many :accepted_friendships,
            :class_name => 'Friendship',
            :conditions => {:status => 'accepted'}
          
          # return all denied friendships you requested
          has_many :denied_friendships,
            :class_name => 'Friendship',
            :conditions => {:status => 'denied'}
        end
      end
      
      module InstanceMethods
        def friendship_for(friend)
          for_conditions = [friend, self].flatten
          Friendship.find(:first, :conditions => ["friend_id IN(?) AND user_id IN(?)", for_conditions, for_conditions])
        end
        
        def friendship_status_for(friend)
          friendship = friendship_for(friend)
          return friendship.status.to_sym if friendship
          return nil
        end
        
        def friendship_status?(friend, status)
          friendship_status_for(friend) == status.to_sym
        end
        
        def be_friend_with(friend)
          # Users are already friends
          return friendship_for(friend) if friend_with?(friend)
          
          # Check if I have a request from this user; if so, just create the friendship
          friendship = requested_friendships.find(:first, :conditions => {:user_id => id_for(friend)})          
          return friendship if friendship && friendship.accept!
          
          # Check if a friendship has been already requested
          return friendship if friendship_status_for(friend) == :pending
          
          # Has a friendship request, so set it to pending
          friendship = friendship_for(friend)
          return friendship if friendship && friendship.pending!
          
          # Yay! Just request a friendship
          friendship = friendships.create(:friend_id => id_for(friend), :requested_at => Time.now, :status => 'pending')
          return friendship
        end
        
        def friend_with?(friend)
          friendship_status?(friend, :accepted)
        end
        
        def accept_friendship_with(friend)
          friendship = friendship_for(friend)
          return friendship if friendship && friendship.accept!
          false
        end
        
        def deny_friendship_with(friend)
          friendship = friendship_for(friend)
          return friendship if friendship && friendship.deny!
          false
        end
        
        def remove_friendship_with(friend)
          friendship = friendship_for(friend)
          return friendship if friendship && friendship.destroy
          false
        end
        
        def mutual_friends(friend, options={})
          common_friends_ids = (friend_ids & friend.friend_ids).uniq
          User.find(common_friends_ids, options)
        end
        
        def possible_friends(friend, options={})
          not_friends_ids = (friend_ids - friend.friend_ids).uniq
          User.find(not_friends_ids, options)
        end
        
        def is?(friend)
          self == friend
        end
        
        private
          def id_for(object)
            return nil unless object
            return object.id unless object.is_a?(Integer)
            return object
          end
      end
    end
  end
end