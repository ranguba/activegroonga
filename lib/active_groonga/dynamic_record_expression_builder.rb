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
  class DynamicRecordExpressionBuilder
    # Instantiates a new dynamic record expression builder.
    #
    # +record+ is a Groonga::RecordExpressionBuilder.
    def initialize(record)
      @record = record
      define_column_readers
    end

    def [](name)
      @record[name]
    end

    private
    def define_column_readers
      singleton_class = class << self; self; end
      @record.table.columns.each do |column|
        singleton_class.send(:define_method, column.local_name) do ||
          self[column.local_name]
        end
      end
    end
  end
end
