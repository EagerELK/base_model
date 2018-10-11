# frozen_string_literal: true

require 'yaml'
require 'base_model'
require 'base_model/file_model'
require 'active_support/inflector'
require 'active_support/core_ext/object/blank'

module BaseModel
  class YamlFileModel < FileModel
    module InstanceMethods
      def parsed_content
        return nil if content.blank?

        YAML.safe_load(content).deep_symbolize_keys if path
      rescue StandardError => e
        logger.warn e.message
        nil
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
