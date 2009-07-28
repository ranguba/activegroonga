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
        initialize_schema_management_tables
        instance_eval(&block)

        unless info[:version].blank?
          assume_migrated_upto_version(info[:version])
        end
      end

      def assume_migrated_upto_version(version)
        version = version.to_i
        table_name = Migrator.groonga_schema_migrations_table_name

        migrations_table = Base.context[table_name]
        migrated = migrations_table.records.collect do |record|
          record["version"].to_i
        end
        versions = Dir['db/migrate/[0-9]*_*.rb'].map do |filename|
          filename.split('/').last.split('_').first.to_i
        end

        unless migrated.include?(version)
          migrations_table.add(version.to_s)
        end

        inserted = Set.new
        (versions - migrated).each do |v|
          if inserted.include?(v)
            raise "Duplicate migration #{v}. Please renumber your migrations to resolve the conflict."
          elsif v < version
            migration = migrations_table.add
            migration["version"] = v.to_s
            inserted << v
          end
        end
      end

      def initialize_schema_management_tables
        initialize_migrations_table
      end

      def create_table(name, options={})
        table_definition = TableDefinition.new(name)
        yield(table_definition)
        table_definition.create
      end

      def drop_table(name, options={})
        table = Base.context[Base.groonga_table_name(name)]
        table.remove
      end

      def add_column(table_name, column_name, type, options={})
        column = ColumnDefinition.new(table_name, column_name)
        case type.to_s
        when "references"
          table = options.delete(:to) || column_name.pluralize
          column.type = Base.groonga_table_name(table)
        else
          column.type = type
        end
        column.create(options)
      end

      def remove_column(table_name, *column_names)
        column_names.each do |column_name|
          ColumnDefinition.new(table_name, column_name).remove
        end
      end

      def add_index_column(table_name, target_table_name, target_column_name,
                           options={})
        column_name = options.delete(:name)
        column_name ||= [target_table_name, target_column_name].join("_")
        column = IndexColumnDefinition.new(table_name, column_name,
                                           target_table_name, target_column_name)
        column.create(options)
      end

      private
      def initialize_migrations_table
        table_name = Migrator.schema_migrations_table_name
        groonga_table_name = Migrator.groonga_schema_migrations_table_name
        if Base.context[groonga_table_name].nil?
          table_file = File.join(Base.metadata_directory,
                                 "#{table_name}.groonga")
          Groonga::Hash.create(:name => groonga_table_name,
                               :path => table_file,
                               :key_type => "ShortText")
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
        table_name = Base.groonga_table_name(@name)
        unless Base.context[table_name]
          Groonga::Array.create(:name => table_name,
                                :path => table_file,
                                :sub_records => true)
        end
        @columns.each(&:create)
      end

      def column(name, type, options={})
        column = self[name] || ColumnDefinition.new(@name, name)
        column.type = type
        @columns << column unless @columns.include?(column)
        self
      end

      def index(target_table_name, target_column_name, options={})
        name = options.delete(:name)
        name ||= [target_table_name, target_column_name].join("_")
        column = self[name] || IndexColumnDefinition.new(@name, name,
                                                         target_table_name,
                                                         target_column_name)
        @columns << column unless @columns.include?(column)
        self
      end

      def references(*args)
        options = args.extract_options!
        args.each do |col|
          groonga_table_name = Base.groonga_table_name(col.to_s.pluralize)
          table = Base.context[groonga_table_name]
          column(col, table, options)
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
        table = Base.context[Base.groonga_table_name(@table_name)]
        table.define_column(@name,
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
          "ShortText"
        when "text"
          "Text"
        when "integer"
          "Int32"
        when "float"
          "Float"
        when "decimal"
          "Int64"
        when "datetime", "timestamp", "time", "date"
          "Time"
        when "binary"
          "LongText"
        when "boolean"
          "Bool"
        else
          type
        end
      end
    end

    class IndexColumnDefinition
      def initialize(table_name, name, target_table_name, target_column_name)
        @table_name = table_name
        @name = name
        @name = @name.to_s if @name.is_a?(Symbol)
        @target_table_name = target_table_name
        @target_column_name = target_column_name
        if @target_column_name.is_a?(Symbol)
          @target_column_name = @target_column_name.to_s
        end
      end

      def create(options={})
        column_dir = Base.index_columns_directory(@table_name,
                                                  @target_table_name.to_s)
        column_file = File.join(column_dir, "#{@name}.groonga")
        options = {:with_position => true}.merge(options)
        options = options.merge(:path => column_file)
        table = Base.context[Base.groonga_table_name(@table_name)]
        target_table = Base.context[Base.groonga_table_name(@target_table_name)]
        target_column = target_table.column(@target_column_name)
        table.define_index_column(@name, target_column, options)
      end

      def remove
        Base.context[@name].remove
      end
    end
  end
end
