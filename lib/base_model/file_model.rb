# frozen_string_literal: true

require 'base_model/model'
require 'active_support/inflector'
require 'will_paginate/array'

module BaseModel
  class FileModel < Model
    module InstanceMethods
      attr_reader :path, :filename

      alias id filename

      def _save
        # TODO: Convert hash to yaml
        raise 'Unimplemented'
      end

      def _destroy
        # TODO: Remove file
        raise 'Unimplemented'
      end

      def method_missing(method, *args, &block)
        return super unless respond_to_missing?(method)
        @stat.send(method, *args, &block)
      end

      def respond_to_missing?(method, _include_private = false)
        @stat.respond_to? method
      end

      def name
        File.basename(filename, '.*').humanize.titleize
      end

      def path
        File.expand_path(File.join(source, filename)) if source && filename
      end

      def stat
        @stat ||= File::Stat.new(path)
      end

      def content
        File.read(path) if path
      end
    end

    module ClassMethods
      def def_FileModel(mod)
        model = self
        mod.define_singleton_method(:FileModel) do |source, extension = '*'|
          model.FileModel(source, extension)
        end
      end

      def FileModel(source, extension = '*')
        klass = Class.new(self)
        klass.source = source
        klass.extension = extension
        klass
      end

      def source=(source)
        raise 'Folder does not exist' unless File.exist?(source)
        super
      end

      def extension=(extension)
        @extension = extension
      end

      def extension
        @extension || '*'
      end

      def primary_key
        :filename
      end

      def dataset
        Dir[File.join(source, "*.#{extension}")].map { |path| new filename: File.basename(path) }
      end

      def all
        dataset
      end

      def where(filters = {})
        all.keep_if do |e|
          filters.reject { |key, value| e.send(key) == value }.count.zero?
        end
      end

      def columns
        %i[id filename content]
      end

      def inherited(subclass)
        super
        ivs = subclass.instance_variables
        unless ivs.include?(:@extension)
          if @extension && self != Model
            subclass.set_extension(@extension.clone)
          end
        end
      end

      def set_extension(extension)
        @extension = extension
        self
      end

      private

      def primary_key_lookup(pk)
        new filename: pk
      end
    end

    extend ClassMethods
    include InstanceMethods

    def_FileModel(::BaseModel)
  end
end
