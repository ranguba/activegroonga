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

    attr_reader :records, :expression, :size
    def initialize(records, klass, options={})
      @records = records
      @klass = klass
      @groups = {}
      @expression = options[:expression]
      if @expression.nil? and @records.respond_to?(:expression)
        @expression = @records.expression
      end
      @size = options[:size] || @records.size
      @n_key_nested = 0
      domain = @records.domain
      while domain.is_a?(Groonga::Table)
        @n_key_nested += 1
        domain = domain.domain
      end
    end

    def paginate(sort_keys, options={})
      set = self.new(@records.paginate(sort_keys, options), @klass,
                     :expression => @expression)
      set.extend(PaginationProxy)
      set
    end

    def sort(keys, options={})
      self.new(@records.sort(keys, options), @klass,
               :expression => @expression)
    end

    def group(key)
      @groups[key] ||= @records.group(key)
    end

    def each
      @records.each do |record|
        object = instantiate(record)
        next if object.nil?
        yield(object)
      end
    end

    private
    def instantiate(record)
      @n_key_nested.times do
        return nil if record.nil?
        record = record.key
      end
      return nil if record.nil?
      @klass.instantiate(record)
    end

    module PaginationProxy
      Groonga::Pagination.instance_methods.each do |method_name|
        define_method(method_name) do
          @records.send(method_name)
        end
      end
    end
  end
end
