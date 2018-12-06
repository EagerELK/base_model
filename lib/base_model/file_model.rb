# frozen_string_literal: true

require 'base_model/model'
require 'active_support/inflector'
require 'will_paginate/array'

module BaseModel
  class FileModel < Model
    module InstanceMethods
      attr_reader :path, :stat

      def initialize(values = {})
        super
        @path = File.expand_path(File.join(source, filename)) if filename
      end

      def id=(value)
        change_column_value(:id, value)
        change_column_value(:filename, value)
        if value.nil?
          @path = nil
          @stat = nil
        else
          @path = File.expand_path(File.join(source, filename))
          @stat = File::Stat.new(@path) if File.exist? @path
        end
        @content = nil
      end

      def filename
        id
      end

      def filename=(value)
        self.id = value
      end

      def _save
        File.open(path, 'wb') do |f|
          f.rewind if f.is_a? Tempfile
          f.write(content.is_a?(Tempfile) ? content.read : content)
        end
      end

      def _destroy
        # TODO: Remove file
        raise 'Unimplemented'
      end

      def [](key)
        return super unless stat.respond_to?(key.to_sym)

        stat.send(key.to_sym)
      end

      def []=(key, value)
        raise 'Read only property' if %i[path stat].include?(key)

        change_column_value(key.to_sym, value)
      end

      def name
        File.basename(filename, '.*').humanize.titleize
      end

      def content
        @content ||= File.read(path) if path
      end

      # value can be a string, or a Tempfile
      # if Tempfile, only write to the path when saving
      def content=(value)
        @content = value
      end

      def upload(file)
        self.filename = File.basename(file[:filename])
        self.content = file[:tempfile]
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
        raise "Folder does not exist: #{source}" unless File.exist?(source)

        super
      end

      def extension=(extension)
        @extension = extension
      end

      def extension
        @extension || '*'
      end

      def primary_key
        :id
      end

      def dataset
        Dir[File.join(source, "*.#{extension}")].map { |path| new id: File.basename(path) }
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
        %i[id filename name path stat content]
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
        new id: pk
      end
    end

    extend ClassMethods
    include InstanceMethods

    def_FileModel(::BaseModel)
  end
end
