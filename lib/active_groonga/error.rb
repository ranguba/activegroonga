# Copyright (C) 2009-2010  Kouhei Sutou <kou@clear-code.com>
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
  # Generic ActiveGroonga exception class.
  class Error < StandardError
  end

  class RecordNotSaved < Error
  end

  class NoKeyTableError < Error
    attr_reader :table
    def initialize(table)
      @table = table
      super("table doesn't have key: #{@table}")
    end
  end

  class KeyOverrideError < Error
    attr_reader :table, :key
    def initialize(table, key)
      @table = table
      @key = key
      super("can't override existing record key: #{@table}: <#{@key}>")
    end
  end
end
