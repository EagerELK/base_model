# frozen_string_literal: true

require 'yaml'
require 'base_model'
require 'base_model/file_model'
require 'active_support/inflector'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/keys'

module BaseModel
  class YamlFileModel < FileModel
    module InstanceMethods
      def parsed_content
        return nil if content.blank?

        @parsed_content ||= YAML.safe_load(content).deep_symbolize_keys if path
      rescue StandardError => e
        logger.warn e.message
        nil
      end

      def _save
        @content = parsed_content.deep_stringify_keys.to_yaml
        super
      end

      def set_column_value(column, value)
        super(column, value)
        return if %i[id filename].include? column.to_sym
        @parsed_content ||= {}
        @parsed_content[column.to_sym] = value
      end
    end

    module ClassMethods
      def def_YamlFileModel(mod)
        model = self
        mod.define_singleton_method(:YamlFileModel) do |source, extension = 'yaml'|
          model.YamlFileModel(source, extension)
        end
      end

      def YamlFileModel(source, extension = 'yaml')
        klass = Class.new(self)
        klass.source = source
        klass.extension = extension
        klass
      end
    end

    extend ClassMethods
    include InstanceMethods

    def_YamlFileModel(::BaseModel)
  end
end
