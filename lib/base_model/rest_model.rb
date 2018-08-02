# frozen_string_literal: true

require 'json'
require 'base_model/model'
require 'active_support/inflector'

module BaseModel
  class RestModel < Model
    module InstanceMethods
      def _save(opts = {})
        opts[:changed] = true if opts[:changed].nil?
        if new?
          connection.call(:post, source, as_parameter.to_json)
          # TODO: Refresh values
        else
          cols_to_save = opts[:columns]
          if cols_to_save.nil?
            cols_to_save = opts[:changed] ? changed_columns : columns
          end
          columns_updated = @values.reject{|k,v| !cols_to_save.include?(k)}
          connection.call(:put, "#{source}/#{pk}", as_parameter(columns_updated).to_json)
        end
      end

      def _destroy
        connection.call(:delete, "#{source}/#{pk}")
      end

      def as_parameter(vals = nil)
        vals ||= values
        { self.class.to_s.demodulize.underscore => vals }
      end
    end

    module ClassMethods
      def def_RestModel(mod)
        model = self
        mod.define_singleton_method(:RestModel) do |source|
          model.RestModel(source)
        end
      end

      def RestModel(source)
        klass = Class.new(self)
        klass.source = source
        klass
      end

      def dataset
        # TODO Return a Dataset class so that we can override count and other methods
        connection.call(:get, source).map { |e| new e }
      end

      def all
        dataset
      end

      def where(filters = {})
        raise 'Unimplemented'
      end

      def columns
        raise 'Unimplemented'
      end

      def connection
        return @connection if @connection
        @connection = RestConnection.connections.first
        raise(Error, "No connection associated with #{self}: have you connected to a data source?") unless @connection
        @connection
      end

      def primary_key_lookup(pk)
        new connection.call(:get, "#{source}/#{pk}")
      end
    end

    extend ClassMethods
    include InstanceMethods

    def_RestModel(::BaseModel)
  end
end
