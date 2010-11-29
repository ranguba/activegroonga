# Copyright (C) 2009-2010  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require 'fileutils'

require 'active_support/all'

module ActiveGroonga
  class Base
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::AttributeMethods
    attribute_method_suffix ""
    attribute_method_suffix "="

    cattr_accessor :logger, :instance_writer => false

    cattr_reader :database_path, :instance_reader => false

    @@configurations = {}
    cattr_accessor :configurations

    @@context = nil
    @@encoding = "utf8"
    cattr_reader :encoding, :instance_reader => false

    class << self
      def configure(configuration)
        case configuration
        when String, Symbol
          configure(configurations[configuration.to_s])
        when Hash
          self.database_path = configuration["database"]
          self.encoding = configuration["encoding"]
        end
      end

      def database
        @@database ||= Database.new(database_path)
      end

      def create(attributes=nil, &block)
        if attributes.is_a?(Array)
          attributes.collect do |nested_attributes|
            create(nested_attributes, &block)
          end
        else
          object = new(attributes)
          yield(object) if block_given?
          object.save
          object
        end
      end

      def find(record_id, options={})
        record_id = record_id.record_id if record_id.respond_to?(:record_id)
        unless table.support_key?
          begin
            record_id = Integer(record_id)
          rescue ArgumentError
            return nil
          end
          return nil unless table.exist?(record_id)
        end
        record = table[record_id]
        return nil if record.nil?
        instantiate(record)
      end

      def exists?(record_id)
        record_id = record_id.record_id if record_id.respond_to?(:record_id)
        if table.support_key?
          not table[record_id].nil?
        else
          begin
            record_id = Integer(record_id)
          rescue ArgumentError
            return false
          end
          table.exist?(record_id)
        end
      end

      def select(options={})
        return all(options) unless block_given?
        records = table.select do |record|
          yield(record)
        end
        ResultSet.new(records, self, :expression => records.expression)
      end

      def all(options={})
        ResultSet.new(table, self)
      end

      def count
        table.size
      end

      def context
        Groonga::Context.default
      end

      def encoding=(new_encoding)
        return if @@encoding == new_encoding
        @@encoding = new_encoding
        database_opened = !context.database.nil?
        Groonga::Context.default = nil
        Groonga::Context.default_options = {:encoding => @@encoding}
        database.reopen if database_opened
      end

      def table_name(name=nil)
        if name.nil?
          @table_name ||= model_name.plural
        else
          self.table_name = name
        end
      end

      def table_name=(name)
        @table_name = name
      end

      def table
        @table ||= context[table_name]
      end

      def define_column_accessors
        attribute_names = table.columns.collect do |column|
          column.local_name
        end
        define_attribute_methods(attribute_names)
      end

      def inspect
        return super if table.nil?
        columns_info = table.columns.collect do |column|
          "#{column.local_name}: #{column.range.name}"
        end
        "#{name}(#{columns_info.join(', ')})"
      end

      def instantiate(record)
        object = new(record)
        object.instance_variable_set("@id", record.id)
        if record.support_key?
          object.instance_variable_set("@key", record.key)
        end
        object.instance_variable_set("@new_record", false)
        object
      end

      def define_method_attribute(name)
        generated_attribute_methods.module_eval do
          define_method(name) do
            read_attribute(name)
          end
        end
      end

      def define_method_attribute=(name)
        generated_attribute_methods.module_eval do
          define_method("#{name}=") do |new_value|
            write_attribute(name, new_value)
          end
        end
      end

      def database_path=(path)
        path = Pathname(path) if path.is_a?(String)
        @@database_path = path
        @@database = nil
      end

      def reference_class(column_name, klass)
        @reference_mapping ||= {}
        column_name = column_name.to_s
        @reference_mapping[column_name] = klass
      end

      def custom_reference_class(column_name)
        @reference_mapping ||= {}
        column_name = column_name.to_s
        @reference_mapping[column_name]
      end

      def i18n_scope
        :activegroonga
      end

      protected
      def instance_method_already_implemented?(method_name)
        super(method_name)
      end
    end

    def initialize(record_or_attributes=nil)
      self.class.define_column_accessors
      @id = nil
      @key = nil
      @new_record = true
      @destroyed = false
      @attributes = initial_attributes
      @attributes_cache = {}
      if record_or_attributes.is_a?(Groonga::Record)
        reload_attributes(record_or_attributes)
      else
        reload_attributes
        self.attributes = (record_or_attributes || {})
      end
    end

    def have_column?(name)
      table.have_column?(name)
    end

    def id
      @id
    end

    def key
      @key
    end

    def key=(key)
      raise NoKeyTableError.new(table) unless table.support_key?
      raise KeyOverrideError.new(table, key) unless new_record?
      @key = key
    end

    def record_id
      if table.support_key?
        key
      else
        id
      end
    end

    def record_raw_id
      id
    end

    def to_key
      persisted? ? [record_id] : nil
    end

    def attributes
      @attributes
    end

    def attributes=(attributes)
      attributes.each do |key, value|
        send("#{key}=", value)
      end
    end

    def ==(other)
      other.is_a?(self.class) and other.id == id
    end

    def hash
      id.hash
    end

    def read_attribute(name)
      @attributes[name]
    end

    def write_attribute(name, value)
      @attributes[name] = value
    end

    def inspect
      inspected_attributes = []
      if table.support_key?
        inspected_attributes << "key: #{key}"
      else
        inspected_attributes << "id: #{id}"
      end
      @attributes.each do |key, value|
        inspected_attributes << "#{key}: #{value.inspect}"
      end
      "\#<#{self.class.name} #{inspected_attributes.join(', ')}>"
    end

    def table
      @table ||= self.class.table
    end

    private
    def attribute(name)
      read_attribute(name)
    end

    def attribute=(name, value)
      write_attribute(name, value)
    end

    include Persistence
    include Validations
    include Callbacks
  end
end

ActiveSupport.run_load_hooks(:active_groonga, ActiveGroonga::Base)
