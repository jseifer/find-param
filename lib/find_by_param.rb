module FindByParam
  module ClassMethods
    def define_find_param(param, options={})
      param = param.to_s
      options[:raise_on_not_found] ||= false
      if column_names.include?(param)
        write_inheritable_attribute :find_parameter, param
        write_inheritable_attribute :find_param_options, options
        bl = lambda do |args|
          results = send("find_by_#{read_inheritable_attribute(:find_parameter)}", *args)
          raise ActiveRecord::RecordNotFound if options[:raise_on_not_found] && (results.nil? or (results.is_a?(Array) && results.empty?))
          return results
        end
        self.class.send(:define_method, 'find_by_param', &bl)
      else
        raise StandardError
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