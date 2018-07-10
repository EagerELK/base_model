# frozen_string_literal: true

require 'json'
require 'base_model/model'
require 'active_support/inflector'

module BaseModel
  class RestModel < Model
    module InstanceMethods
      def _save
        if new?
          connection.call(:post, source, values.to_json)
          # TODO: Refresh values
        else
          connection.call(:put, "#{source}/#{pk}", values.to_json)
        end
      end

      def _destroy
        connection.call(:delete, "#{source}/#{pk}")
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

      def primary_key_lookup(pk)
        new connection.call(:get, "#{source}/#{pk}")
      end
    end

    extend ClassMethods
    include InstanceMethods

    def_RestModel(::BaseModel)
  end
end
