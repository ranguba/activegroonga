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

require 'active_record/connection_adapters/abstract/schema_definitions'

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

    def type_cast_code(var_name)
      nil
    end

    def number?
      super or type == :unsigned_integer
    end

    private
    def detect_type
      case @column.range
      when Groonga::Type::INT
        :integer
      when Groonga::Type::UINT
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
        if Base.context[@column.range]
          :references
        else
          :string
        end
      end
    end
  end
end
