# frozen_string_literal: true

require 'logger'
require 'sequel/model/errors'

module BaseModel
  class ValidationFailed < StandardError
  end

  class ConnectionError < StandardError
  end

  class Model
    module InstanceMethods
      def initialize(values = {})
        @values = {}
        initialize_columns
        set values
        _changed_columns.clear
        yield self if block_given?
      end

      def initialize_columns
        self.class.columns.each do |k|
          self.class.send(:define_method, k, proc { self[k] }) unless self.class.method_defined?(k)
          self.class.send(:define_method, "#{k}=", proc { |var| self[k] = var }) unless self.class.method_defined?("#{k}=")
        end
      end

      # Returns the primary key value identifying the model instance.
      def pk
        raise 'Unimplemented'
      end

      def new?
        pk.nil?
      end

      def set(values = {})
        return self if values.empty?
        values.each do |k, v|
          next unless self.class.columns.include?(k.to_sym)
          change_column_value(k, v)
        end
      end

      def values
        @values
      end

      def update(values = {})
        set(values)
        save
      end

      # Easy access to attributes
      def [](key)
        @values[key.to_sym]
      end

      def []=(key, value)
        change_column_value(key.to_sym, value)
      end

      def errors
        @errors ||= Sequel::Model::Errors.new
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
        _changed_columns.clear
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
        @connection ||= self.class.connection
      end

      def connection=(connection)
        @connection = connection
      end

      def source
        self.class.source
      end

      def columns
        self.class.columns
      end

      def changed_columns
        _changed_columns
      end

      def change_column_value(column, value)
        _add_changed_column(column)
        set_column_value(column, value)
      end

      def set_column_value(column, value)
        @values[column.to_sym] = value
      end

      # Just return the object to ensure Sequel compatibility
      def transaction
        yield self if block_given?
        self
      end

      def db
        yield self if block_given?
        self
      end

      private

      def _add_changed_column(column)
        _changed_columns << column unless _changed_columns.include?(column)
      end

      def _changed_columns
        @changed_columns ||= []
      end
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

      def with_pk(pk)
        primary_key_lookup(pk)
      end

      def with_pk!(pk)
        with_pk || raise('Could not find the specified object')
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
