require File.dirname(__FILE__) + '/lib/has_friends'
require File.dirname(__FILE__) + '/lib/friendship'

ActiveRecord::Base.send(:include, SimplesIdeias::Friends)
