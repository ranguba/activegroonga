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
      @indexes = []
      header(stream)
      dump_tables(stream)
      dump_references(stream)
      dump_indexes(stream)
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

        table_name = Base.groonga_table_name(name)
        table = Base.context[table_name]
        options = [":force => true"]
        case table
        when Groonga::Hash
          options << ":type => :hash"
        when Groonga::PatriciaTrie
          options << ":type => :patricia_trie"
        end
        if table.domain
          options << ":key_type => #{table.domain.name.inspect}"
        end
        if table.respond_to?(:default_tokenizer) and table.default_tokenizer
          options << ":default_tokenizer => #{table.default_tokenizer.name.inspect}"
        end

        table_schema.puts "  create_table #{name.inspect}, #{options.join(', ')} do |t|"
        column_specs = []
        columns(name).each do |column|
          if column.reference_type?
            @references << [name, column]
            next
          end
          if column.index?
            @indexes << [name, column]
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

    def dump_references(stream)
      @references.sort_by do |name, column|
        [name, column.name]
      end.each do |name, column|
        statement = "  add_column #{name.inspect}, "
        statement << "#{column.name.inspect}, "
        statement << "#{column.reference_object_name.inspect}"
        stream.puts(statement)
      end
    end

    def dump_indexes(stream)
      @indexes.sort_by do |name, column|
        [name, column.name]
      end.each do |name, column|
        column.index_sources.each do |source|
          statement = "  add_index_column #{name.inspect}, "
          statement << "#{source.table.name.inspect}, "
          statement << "#{source.local_name.inspect}, "
          statement << ":name => #{column.name.inspect}"
          stream.puts(statement)
        end
      end
    end

    def columns(table_name)
      table_name = Base.groonga_table_name(table_name)
      Base.context[table_name].columns.collect {|column| Column.new(column)}
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
