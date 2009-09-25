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
  class Column < ActiveRecord::ConnectionAdapters::Column
    # Instantiates a new column in the table.
    #
    # +column+ is the Groonga::Column.
    def initialize(column)
      @column = column
      @name = column.name.split(/\./, 2)[1]
      @type = detect_type
    end

    def id?
      false
    end

    def type_cast(value)
      return nil if value.nil?
      case type
      when :references
        if value.is_a?(ActiveGroonga::Base)
          value
        else
          reference_object_class.find(value)
        end
      else
        super
      end
    end

    def type_cast_code(var_name)
      case type
      when :references
        "#{reference_object_class.name}.find(#{var_name})"
      else
        super
      end
    end

    def number?
      super or type == :unsigned_integer
    end

    def quote(value)
      case value
      when ActiveGroonga::Base
        Groonga::Record.new(value.class.table, value.id)
      else
        value
      end
    end

    def index?
      @type == :index
    end

    def index_sources
      if @column
        @column.sources
      else
        []
      end
    end

    def reference_type?
      @type == :references
    end

    def reference_object_name
      return nil unless reference_type?
      @column.range.name.gsub(/(?:\A<table:|>\z)/, '')
    end

    def reference_object_class
      table_name = reference_object_name
      return nil if table_name.nil?
      table_name.camelcase.singularize.constantize
    end

    private
    def detect_type
      return :index if @column.is_a?(Groonga::IndexColumn)
      case @column.range
      when Groonga::Type
        case @column.range.id
        when Groonga::Type::INT32
          :integer
        when Groonga::Type::UINT32, Groonga::Type::UINT64
          :unsigned_integer
        when Groonga::Type::INT64
          :decimal
        when Groonga::Type::FLOAT
          :float
        when Groonga::Type::TIME
          :time
        when Groonga::Type::SHORT_TEXT
          :string
        when Groonga::Type::TEXT, Groonga::Type::LONG_TEXT
          :text
        else
          :string
        end
      when Groonga::Table
        :references
      else
        :string
      end
    end
  end

  class IdColumn < Column
    def initialize(table)
      @column = nil
      @table = table
      @name = "id"
      @type = :unsigned_integer
    end

    def id?
      true
    end
  end
end
