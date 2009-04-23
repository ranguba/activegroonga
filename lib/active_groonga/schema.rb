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
        initialize_index_management_table
        initialize_index_table
        initialize_migrations_table
      end

      def create_table(name, options={})
        table_definition = TableDefinition.new(name)
        yield(table_definition)
        table_definition.create
      end

      def drop_table(name, options={})
        table = Base.context[Base.groonga_table_name(name)]
        table_id = table.id
        table.remove
        index_management_table.open_cursor do |cursor|
          while cursor.next
            cursor.delete if cursor.table_id == table_id
          end
        end
      end

      def add_column(table_name, column_name, type, options={})
        column = ColumnDefinition.new(table_name, column_name)
        if type.to_s == "references"
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

      def add_index(table_name, column_name, options={})
        groonga_table_name = Base.groonga_table_name(table_name)
        table = Base.context[groonga_table_name]
        column_name = column_name.to_s
        column = table.column(column_name)

        base_dir = File.join(Base.metadata_directory,
                             index_table_name,
                             table_name)
        FileUtils.mkdir_p(base_dir)

        name = "#{table_name}/#{column_name}"
        path = File.join(base_dir, "#{column_name}.groonga")
        index_column = index_table.define_column(name, column,
                                                 :path => path,
                                                 :type => "index",
                                                 :compress => "zlib",
                                                 :with_section => true,
                                                 :with_weight => true,
                                                 :with_position => true)
        index_column.source = column

        record = index_management_table.add
        record["table"] = groonga_table_name
        record["column"] = column_name
        record["index"] = name
      end

      def index_management_table
        Base.context[groonga_index_management_table_name]
      end

      def index_table
        Base.context[groonga_index_table_name]
      end

      def indexes(table_or_table_name)
        if table_or_table_name.is_a?(String)
          table_name = table_or_table_name
          table = Base.context[Base.groonga_table_name(table_name)]
        else
          table = table_or_table_name
          table_name = table.name.gsub(/(?:\A<table:|>\z)/, '')
        end
        indexes = []
        index_management_table.records.each do |record|
          next if record["table"] != table.name
          indexes << IndexDefinition.new(table_name, record["index"],
                                         false, record["column"])
        end
        indexes
      end

      private
      def index_management_table_name
        Base.table_name_prefix + 'indexes' + Base.table_name_suffix
      end

      def groonga_index_management_table_name
        Base.groonga_metadata_table_name(index_management_table_name)
      end

      def index_table_name
        Base.table_name_prefix + 'index' + Base.table_name_suffix
      end

      def groonga_index_table_name
        Base.groonga_metadata_table_name(index_table_name)
      end

      def initialize_index_management_table
        table_name = index_management_table_name
        groonga_table_name = groonga_index_management_table_name
        if Base.context[groonga_table_name].nil?
          table_file = File.join(Base.metadata_directory,
                                 "#{table_name}.groonga")
          table = Groonga::Array.create(:name => groonga_table_name,
                                        :path => table_file)

          base_dir = File.join(Base.metadata_directory, table_name)
          FileUtils.mkdir_p(base_dir)

          column_file = File.join(base_dir, "table.groonga")
          table.define_column("table", "<shorttext>", :path => column_file)

          column_file = File.join(base_dir, "column.groonga")
          table.define_column("column", "<shorttext>", :path => column_file)

          column_file = File.join(base_dir, "index.groonga")
          table.define_column("index", "<shorttext>", :path => column_file)
        end
      end

      def initialize_index_table
        table_name = index_table_name
        groonga_table_name = groonga_index_table_name
        if Base.context[groonga_table_name].nil?
          table_file = File.join(Base.metadata_directory,
                                 "#{table_name}.groonga")
          table = Groonga::PatriciaTrie.create(:name => groonga_table_name,
                                               :path => table_file,
                                               :key_with_sis => true,
                                               :key_normalize => true)
          # table.default_tokenizer = "<token:mecab>"

          base_dir = File.join(Base.metadata_directory, table_name)
          FileUtils.mkdir_p(base_dir)
        end
      end

      def initialize_migrations_table
        table_name = Migrator.schema_migrations_table_name
        groonga_table_name = Migrator.groonga_schema_migrations_table_name
        if Base.context[groonga_table_name].nil?
          table_file = File.join(Base.metadata_directory,
                                 "#{table_name}.groonga")
          Groonga::Hash.create(:name => groonga_table_name,
                               :path => table_file,
                               :key_type => "<shorttext>")
        end
      end
    end

    class TableDefinition < ActiveRecord::ConnectionAdapters::TableDefinition
      undef_method :primary_key, :to_sql, :native

      def initialize(name)
        super(nil)
        @name = name
        @indexes = []
      end

      def create
        table_file = File.join(Base.tables_directory, "#{@name}.groonga")
        Groonga::Array.create(:name => Base.groonga_table_name(@name),
                              :path => table_file)
        @columns.each(&:create)
        @indexes.each do |column_name, options|
          Schema.add_index(@name.to_s, column_name, options)
        end
      end

      def column(name, type, options={})
        column = self[name] || ColumnDefinition.new(@name, name)
        column.type = type
        @columns << column unless @columns.include?(column)
        self
      end

      def index(column_name, options={})
        @indexes << [column_name.to_s, options]
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

    class IndexDefinition < ActiveRecord::ConnectionAdapters::IndexDefinition
      alias_method :column, :columns
      alias_method :column=, :columns=
    end
  end
end
