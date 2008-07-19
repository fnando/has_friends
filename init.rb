require "has_friends"
ActiveRecord::Base.send(:include, SimplesIdeias::Acts::Friendships)

require File.dirname(__FILE__) + "/lib/friendship"