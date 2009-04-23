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
  class SchemaDumper < ActiveRecord::SchemaDumper
    class << self
      def dump(stream=STDOUT)
        new.dump(StreamWrapper.new(stream))
        stream
      end
    end

    def initialize
      @version = Migrator.current_version
    end

    def dump(stream)
      @references = []
      header(stream)
      dump_tables(stream)
      dump_references(stream)
      trailer(stream)
      stream
    end

    private
    def dump_tables(stream)
      tables.sort.each do |name|
        next if ignore_tables.any? {|ignored| ignored === name}
        dump_table(name, stream)
      end
    end

    def tables
      Dir[File.join(Base.tables_directory, "*.groonga")].collect do |path|
        File.basename(path, ".groonga")
      end
    end

    def dump_table(name, stream)
      begin
        table_schema = StringIO.new
        table_schema.puts "  create_table #{name.inspect}, :force => true do |t|"
        column_specs = []
        columns(name).each do |column|
          if column.reference_type?
            @references << [name, column]
            next
          end

          spec = {}
          spec[:type] = column.type.to_s
          spec[:name] = column.name.inspect
          column_specs << spec
        end

        column_specs.each do |spec|
          table_schema.print("    t.#{spec[:type]} #{spec[:name]}")
          table_schema.puts
        end

        table_schema.puts "  end"
        table_schema.puts

        dump_indexes(name, table_schema)

        stream.print table_schema.string
      rescue => e
        stream.puts "# Could not dump table #{name.inspect} because of following #{e.class}"
        stream.puts "#   #{e.message}"
        e.backtrace.each do |trace|
          stream.puts "#   #{trace}"
        end
        stream.puts
      end

      stream
    end

    def dump_indexes(table, stream)
      _indexes = indexes(table)
      return if _indexes.empty?

      add_index_statements = _indexes.collect do |index|
        statement_parts = []
        statement_parts << "add_index #{index.table.inspect}"
        statement_parts << index.columns.inspect
        statement_parts << ":name => #{index.name.inspect}"
        '  ' + statement_parts.join(', ')
      end

      stream.puts add_index_statements.sort.join("\n")
      stream.puts
    end

    def dump_references(stream)
      @references.sort_by do |name, column|
        [name, column.name]
      end.each do |name, column|
        statement = "  add_column #{name.inspect}, "
        statement << "#{column.name.inspect}, :references, "
        statement << ":to => #{column.reference_object_name.inspect}"
        stream.puts(statement)
      end
    end

    def columns(table_name)
      table_name = Base.groonga_table_name(table_name)
      Base.context[table_name].columns.collect {|column| Column.new(column)}
    end

    def indexes(table_name)
      Schema.indexes(table_name)
    end

    class StreamWrapper
      def initialize(stream)
        @stream = stream
      end

      def method_missing(name, *args, &block)
        @stream.send(name, *args.collect {|arg| normalize_string(arg)}, &block)
      end

      private
      def normalize_string(string)
        if string.is_a?(String)
          string.gsub(/Active ?Record/, "ActiveGroonga")
        else
          string
        end
      end
    end
  end
end
