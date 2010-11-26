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
  class Vector
    include Enumerable

    attr_reader :owner, :klass, :values
    def initialize(owner, klass, values=[])
      @owner = owner
      @klass = klass
      @values = values
      @values = [@values] unless @values.is_a?(Array)
    end

    def each
      @values.each do |value|
        yield(instantiate(value))
      end
    end

    def <<(value)
      value = @klass.create(value) if @owner.persisted?
      @values << value
    end

    def to_ary
      to_a
    end

    private
    def instantiate(value)
      if value.is_a?(@klass)
        value
      else
        @klass.instantiate(value)
      end
    end
  end
end
