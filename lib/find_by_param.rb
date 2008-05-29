module FindByParam
  # Catch-all error for any issue arrising within the FindByParam plugin.
  class Error < RuntimeError; end

  # Raised when the param requested is not in the model's table definition:
  #
  #   class WillRaiseError < ActiveRecord::Base
  #     define_find_param :undefined_column
  #   end
  class ColumnNotFoundError < Error; end

  module ClassMethods
    # Defines a finder (#find_by_param) using the specified parameter name.
    # Also, defines #to_param to use the same parameter.
    #
    # Options:
    # * <tt>:raise_on_not_found</tt>: cases ActiveRecord::RecordNotFound to be raised when no record is found
    # * <tt>:initialize_with</tt>: the name of parameter to use to initialize the find parameter when a new record is created
    # * <tt>:using</tt>: a proc used to manipulated the initialization parameter before setting the find parameter
    def find_param(param, options={})
      raise_on_not_found = options.delete(:raise_on_not_found)
      initialize_with = options.delete(:initialize_with)
      raise ColumnNotFoundError unless column_names.include?(param.to_s)

      self.class.send(:define_method, :find_by_param) do |args|
        returning send("find_by_#{param}", *args) do |results|
          raise ActiveRecord::RecordNotFound if raise_on_not_found && (results.nil? || (results.is_a?(Array) && results.size == 0))
        end
      end

      self.send(:alias_method, :to_param, param)

      initialize_parameter(param, initialize_with, options) if initialize_with
    end

    def initialize_parameter(param, source, options={})
      raise ColumnNotFoundError unless column_names.include?(source.to_s)
      using = options.delete(:using)

      self.send(:define_method, :set_param) do
        value = self.send(source)
        value = using.respond_to?(:call) ? using.call(value) : value.downcase.gsub(/[^\w]+/, '-')

        self.send("#{param}=",  value)
      end
      self.send(:private, :set_param)

      self.send(:before_create, :set_param)
    end
    private :initialize_parameter
  end
end
