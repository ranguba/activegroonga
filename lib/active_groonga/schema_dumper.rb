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
        new(ConnectionMock.new).dump(StreamWrapper.new(stream))
        stream
      end
    end

    def initialize(connection)
      @connection = connection
      @types = ["int"]
      @version = Migrator.current_version
    end

    def table(table, stream)
      columns = @connection.columns(table)
      begin
        tbl = StringIO.new
        tbl.puts "  create_table #{table.inspect}, :force => true do |t|"
        column_specs = columns.map do |column|
          spec = {}
          spec[:type] = column.type.to_s
          name = column.name
          spec[:name] = name.inspect
          spec
        end.compact

        column_specs.each do |spec|
          tbl.print("    t.#{spec[:type]} #{spec[:name]}")
          tbl.puts
        end

        tbl.puts "  end"
        tbl.puts

        indexes(table, tbl)

        tbl.rewind
        stream.print tbl.read
      rescue => e
        stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
        stream.puts "#   #{e.message}"
        stream.puts
      end

      stream
    end

    class ConnectionMock
      def tables
        Dir[File.join(Base.tables_directory, "*.groonga")].collect do |path|
          File.basename(path, ".groonga")
        end
      end

      def columns(table_name)
        table_name = Base.groonga_table_name(table_name)
        Base.context[table_name].columns.collect {|column| Column.new(column)}
      end

      def indexes(table_name)
        Schema.indexes(table_name)
      end
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
