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

require 'active_support/all'

module ActiveGroonga
  class Base
    extend ActiveModel::Naming
    include ActiveModel::AttributeMethods
    attribute_method_suffix ""
    attribute_method_suffix "="

    cattr_reader :database_path

    @@configurations = {}
    cattr_accessor :configurations

    class << self
      def configure(configuration)
        case configuration
        when String, Symbol
          configure(configurations[configuration.to_s])
        when Hash
          self.database_path = configuration["database_path"]
        end
      end

      def database
        path = database_path
        return nil if path.nil?
        if path.exist?
          @@database ||= Groonga::Database.open(:path => path.to_s,
                                                :context => context)
        else
          @@databae ||= Groonga::Database.create(path.to_s, :context => context)
        end
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

      def find(*args, &block)
        options = args.extract_options!
        case args.first
        when :first, :last, :all
          send(args.first, &block)
        else
          id = args.first
          id = id.record_id if id.respond_to?(:record_id)
          record = table[id]
          record = instantiate(record) if record
          record
        end
      end

      def first
        return nil if table.empty?
        if block_given?
          records = table.select do |record|
            yield(record)
          end
          return nil if records.empty?
          record = records.find {|record| true}
          instantiate(record.key)
        else
          record = table.find {|record| true}
          instantiate(record)
        end
      end

      def all
        if block_given?
          records = table.select do |record|
            yield(record)
          end
          records.collect do |record|
            instantiate(record.key)
          end
        else
          table.collect do |record|
            instantiate(record)
          end
        end
      end

      def count
        table.size
      end

      def context
        Groonga::Context.default
      end

      def table
        @table ||= context[model_name.plural]
      end

      def define_column_accessors
        attribute_names = table.columns.collect do |column|
          column.local_name
        end
        define_attribute_methods(attribute_names)
      end

      def inspect
        columns_info = table.columns.collect do |column|
          "#{column.local_name}: #{column.range.name}"
        end
        "#{name}(#{columns_info.join(', ')})"
      end

      def instantiate(record)
        object = new(record)
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

      protected
      def instance_method_already_implemented?(method_name)
        super(method_name) and
          !parent.instance_method_already_implemented?(method_name)
      end
    end

    def initialize(record_or_attributes=nil)
      self.class.define_column_accessors
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
      self.class.table.have_column?(name)
    end

    def id
      @id
    end

    def key
      @key
    end

    def record_id
      if table.support_key?
        key
      else
        id
      end
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

    private
    def table
      @table ||= self.class.table
    end

    def attribute(name)
      read_attribute(name)
    end

    def attribute=(name, value)
      write_attribute(name, value)
    end

    include Persistence
    include Callbacks
  end
end
