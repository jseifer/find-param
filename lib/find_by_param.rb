module FindByParam
  
  ##
  # Catch-all error for any issue arrising within the FindByParam plugin.
  #
  class Error < RuntimeError; end
  
  ##
  # Raised when the param requested is not in the model's table definition.
  # For example:
  #
  #     class WillRaiseError < ActiveRecord::Base
  #       define_find_param :undefined_column
  #     end
  #
  class ColumnNotFoundError < Error; end
  
  module ClassMethods
    def define_find_param(param, options={})
      param = param.to_s
      options[:raise_on_not_found] ||= false
      if column_names.include?(param)
        write_inheritable_attribute :find_parameter, param
        write_inheritable_attribute :find_param_options, options
        bl = lambda do |args|
          results = send("find_by_#{read_inheritable_attribute(:find_parameter)}", *args)
          raise ActiveRecord::RecordNotFound if options[:raise_on_not_found] && (results.nil? or (results.is_a?(Array) && results.size == 0))
          return results
        end
        self.class.send(:define_method, 'find_by_param', &bl)
      else
        raise ColumnNotFoundError
      end
      self.send(:include, FindByParam::InstanceMethods)
    end
  end
  
  module InstanceMethods
    def to_param
      self.send(self.class.read_inheritable_attribute(:find_parameter))
    end
  end
end