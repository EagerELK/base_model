# frozen_string_literal: true

require 'logger'

module BaseModel
  class ValidationFailed
  end

  class Error < StandardError
  end

  class Errors
    include Enumerable

    def initialize
      @collection = []
    end

    def each
      @collection.each do |val|
        yield val
      end
    end
  end

  class Model
    module InstanceMethods
      def initialize(values = {})
        set values
        # TODO: yield
      end

      def pk
        raise 'Unimplemented'
      end

      def new?
        pk.nil?
      end

      def set(values = {})
        values.each do |k, v|
          next unless self.class.columns.include?(k.to_sym)
          instance_variable_set("@#{k}", v)
          self.class.send(:define_method, k, proc { instance_variable_get("@#{k}") })
          self.class.send(:define_method, "#{k}=", proc { |var| instance_variable_set("@#{k}", var) })
        end
      end

      def values
        columns.map do |c|
          [c, send(c)]
        end.to_h
      end

      def update(values = {})
        set(values)
        save
      end

      # Easy access to attributes
      def [](key)
        send(key) if key.is_a?(String) || key.is_a?(Symbol)
      end

      def []=(key, value)
        send(:"#{key}=", value)
      end

      def errors
        @errors ||= Errors.new
      end

      def validate; end

      def before_validation; end

      def after_validation; end

      def _validate
        before_validation
        validate
        after_validation
      end

      def valid?
        _validate
        errors.count == 0
      end

      def before_save; end

      def after_save; end

      def save
        raise ValidationFailed unless valid?
        before_save
        _save
        after_save
      end

      def _save
        raise 'Unimplemented'
      end

      def before_destroy; end

      def after_destroy; end

      def destroy
        before_destroy
        _destroy
        after_destroy
      end

      def _destroy
        raise 'Unimplemented'
      end

      def refresh
        set primary_key_lookup(pk)
      end

      def logger
        @logger ||= Logger.new($stdout)
      end

      def connection
        self.class.connection
      end

      def source
        self.class.source
      end

      def columns
        self.class.columns
      end

      # def method_missing(method, *args, &block)
      #   return super unless respond_to_missing?(method)
      #   self.class.send(method, *args, &block)
      # end

      # def respond_to_missing?(method, _include_private = false)
      #   self.class.respond_to? method
      # end
    end

    module ClassMethods
      def def_Model(mod)
        model = self
        (class << mod; self; end).send(:define_method, :Model) do |source|
          model.Model(source)
        end
      end

      def Model(source)
        klass = Class.new(self)
        klass.source = source
        klass
      end

      def source=(source)
        raise 'No source given' if source.nil?
        set_source source
      end

      def source
        @source
      end

      def primary_key
        raise 'Unimplemented'
      end

      def connection
        return @connection if @connection
        raise(Error, "No connection associated with #{self}: have you connected to a data source?") unless @connection
        @connection
      end

      def connection=(connection)
        @connection = connection
      end

      def create(values = {}, &block)
        new(values, &block).save
      end

      def [](filters = {})
        find(filters)
      end

      def first(*args, &_block)
        case args.length
        when 0
          dataset.count ? dataset.first : nil
        when 1
          find args[0]
        end
      end

      def first!
        first || raise('Could not find the specified object')
      end

      def find(filters = {})
        filters.is_a?(Hash) ? where(filters).first : (primary_key_lookup(filters) unless filters.nil?)
      end

      def where(_filters = {})
        raise('Unimplemented')
      end

      def all
        raise 'Unimplemented'
      end

      def columns
        raise 'Unimplemented'
      end

      def inherited(subclass)
        super
        ivs = subclass.instance_variables
        unless ivs.include?(:@source)
          if @source && self != Model
            subclass.set_source(@source.clone)
          end
        end
      end

      def set_source(source)
        @source = source
        self
      end

      private

      def primary_key_lookup(_pk)
        raise 'Unimplemented'
      end
    end

    extend ClassMethods
    include InstanceMethods

    def_Model(::BaseModel)
  end
end
