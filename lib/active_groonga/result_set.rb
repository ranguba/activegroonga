# Copyright (C) 2010  Kouhei Sutou <kou@clear-code.com>
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
  class ResultSet
    include Enumerable

    attr_reader :records
    def initialize(records, klass)
      @records = records
      @klass = klass
      @groups = {}
    end

    def paginate(sort_keys, options={})
      @records.paginate(sort_keys, options)
    end

    def size
      @records.size
    end

    def expression
      @records.expression
    end

    def group(key)
      @groups[key] ||= @records.group(key)
    end

    def each
      @records.each do |record|
        yield(instantiate(record.key))
      end
    end

    private
    def instantiate(record)
      @klass.instantiate(record)
    end
  end
end
