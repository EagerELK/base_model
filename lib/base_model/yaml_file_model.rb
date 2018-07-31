# frozen_string_literal: true

require 'yaml'
require 'base_model/file_model'
require 'active_support/inflector'

module BaseModel
  class YamlFileModel < FileModel
    module InstanceMethods
      def content
        YAML.safe_load(super).deep_symbolize_keys if path
      end

      def raw_content
        File.read(path) if path
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
