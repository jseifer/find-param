require 'find_by_param'

ActiveRecord::Base.send(:extend, FindByParam::ClassMethods)
