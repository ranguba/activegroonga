# Copyright (C) 2009  Kouhei Sutou <kou@clear-code.com>
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

module ActiveGroonga
  module Schema
    class << self
      def define(info={}, &block)
        instance_eval(&block)

        unless info[:version].blank?
          initialize_schema_migrations_table
          assume_migrated_upto_version info[:version]
        end
      end

      def initialize_schema_migrations_table
        table_name = Migrator.schema_migrations_table_name
        if Base.context[table_name].nil?
          create_table(table_name) do |table|
            table.string(:version)
          end
        end
      end

      def create_table(name, options={})
        table_definition = TableDefinition.new(name)
        yield(table_definition)
        table_definition.create
      end

      def add_column(table_name, column_name, type, options={})
        column = ColumnDefinition.new(table_name, column_name)
        column.type = type
        column.create(options)
      end

      def remove_column(table_name, *column_names)
        column_names.each do |column_name|
          ColumnDefinition.new(table_name, column_name).remove
        end
      end
    end

    class TableDefinition < ActiveRecord::ConnectionAdapters::TableDefinition
      undef_method :primary_key, :to_sql, :native

      def initialize(name)
        super(nil)
        @name = name
      end

      def create
        table_file = File.join(Base.tables_directory, "#{@name}.groonga")
        Groonga::Array.create(:name => @name, :path => table_file)
        @columns.each(&:create)
      end

      def column(name, type, options={})
        column = self[name] || ColumnDefinition.new(@name, name)
        column.type = type
        @columns << column unless @columns.include?(column)
        self
      end

      def references(*args)
        options = args.extract_options!
        args.each do |col|
          column("#{col}_id", Base.context[col.to_s.pluralize], options)
        end
      end
      alias :belongs_to :references
    end

    class ColumnDefinition
      attr_accessor :name, :type

      def initialize(table_name, name)
        @table_name = table_name
        @name = name
        @name = @name.to_s if @name.is_a?(Symbol)
        @type = nil
      end

      def create(options={})
        column_file = File.join(Base.columns_directory(@table_name),
                                "#{@name}.groonga")
        options = options.merge(:path => column_file)
        Base.context[@table_name].define_column(@name,
                                                normalize_type(@type),
                                                options)
      end

      def remove
        Base.context[@name].remove
      end

      def normalize_type(type)
        return type if type.is_a?(Groonga::Object)
        case type.to_s
        when "string"
          "<shorttext>"
        when "text"
          "<text>"
        when "integer"
          "<int>"
        when "float"
          "<float>"
        when "decimal"
          "<int64>"
        when "datetime", "timestamp", "time", "date"
          "<time>"
        when "binary"
          "<longtext>"
        when "boolean"
          "<int>"
        else
          type
        end
      end
    end
  end
end
