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

      def create_table(name, options={}, &block)
        table_file = File.join(Base.tables_directory, "#{name}.groonga")
        table_name = Base.groonga_table_name(name)
        options = {:path => table_file}.merge(options)
        options = default_table_options(options).merge(options)
        options = options.merge(:context => Base.context)
        Groonga::Schema.create_table(table_name, options) do |table|
          block.call(TableDefinitionWrapper.new(table))
        end
      end

      def remove_table(name, options={})
        options = options.merge(:context => Base.context)
        Groonga::Schema.remove_table(name, options)
      end
      alias_method :drop_table, :remove_table

      def add_column(table_name, column_name, type, options={})
        options_with_context = options.merge(:context => Base.context)
        Groonga::Schema.change_table(table_name, options_with_context) do |table|
          table = TableDefinitionWrapper.new(table)
          table.column(column_name, type, options)
        end
      end

      def remove_column(table_name, *column_names)
        options_with_context = options.merge(:context => Base.context)
        Groonga::Schema.change_table(table_name, options_with_context) do |table|
          column_names.each do |column_name|
            table.remove_column(column_name)
          end
        end
      end

      def add_index_column(table_name, target_table_name, target_column_name,
                           options={})
        options_for_table = options.reject {|key, value| key == :name}
        options_for_table = options_for_table.merge(:context => Base.context)
        Groonga::Schema.change_table(table_name, options_for_table) do |table|
          table = TableDefinitionWrapper.new(table)
          table.index(target_table_name, target_column_name, options)
        end
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

      def default_table_options(options)
        default_options = {:sub_records => true}
        case options[:type]
        when :hash, :patricia_trie
          default_options[:default_tokenizer] = "TokenBigram"
        end
        default_options
      end
    end

    class TableDefinitionWrapper
      def initialize(definition)
        @definition = definition
      end

      def column(name, type, options={})
        column_file = File.join(Base.columns_directory(@definition.name),
                                "#{name}.groonga")
        options = {:path => column_file}.merge(options)
        @definition.column(name, type, options)
      end

      def remove_column(name, options={})
        @definition.remove_column(name, options)
      end
      alias_method :remove_index, :remove_column

      def index(target_table_name, target_column_name, options={})
        column_name = options.delete(:name)
        column_name ||= [target_table_name, target_column_name].join("_")
        column_dir = Base.index_columns_directory(@definition.name,
                                                  target_table_name.to_s)
        column_file = File.join(column_dir, "#{column_name}.groonga")
        options = {:with_position => true, :path => column_file}.merge(options)
        target_table = @definition.context[target_table_name]
        target_column = target_table.column(target_column_name)
        @definition.index(column_name, target_column, options)
      end

      def timestamps(*args)
        options = args.extract_options!
        column(:created_at, :datetime, options)
        column(:updated_at, :datetime, options)
      end

      def string(*args)
        columns("ShortText", *args)
      end

      def text(*args)
        columns("Text", *args)
      end

      def integer(*args)
        columns("Integer32", *args)
      end

      def float(*args)
        columns("Float", *args)
      end

      def decimal(*args)
        columns("Integer64", *args)
      end

      def time(*args)
        columns("Time", *args)
      end
      alias_method :datetime, :time
      alias_method :timestamp, :time

      def binary(*args)
        columns("LongText", *args)
      end

      def boolean(*args)
        columns("Bool", *args)
      end

      def reference(name, table=nil, options={})
        table = Base.groonga_table_name(table || name.to_s.pluralize)
        column(name, table, options)
      end
      alias_method :references, :reference
      alias_method :belongs_to, :references

      private
      def columns(type, *args)
        options = args.extract_options!
        column_names = args
        column_names.each do |name|
          column(name, type, options)
        end
      end
    end
  end
end
