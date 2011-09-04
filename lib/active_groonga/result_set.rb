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

    attr_reader :records, :expression, :n_records
    def initialize(records, klass, options={})
      @records = records
      @klass = klass
      @groups = {}
      @expression = options[:expression]
      if @expression.nil? and @records.respond_to?(:expression)
        @expression = @records.expression
      end
      @n_records = options[:n_records] || @records.size
      @default_sort_keys = options[:default_sort_keys]
      @default_limit = options[:default_limit]
      compute_n_key_nested
    end

    def paginate(sort_keys, options={})
      options[:size] = normalize_limit(options[:size])
      options[:page] = normalize_page(options[:page])
      sort_keys = normalize_sort_keys(sort_keys)
      records = @records.paginate(sort_keys, options)
      set = create_result_set(records)
      set.extend(PaginationProxy)
      set
    end

    def sort(keys, options={})
      keys = normalize_sort_keys(keys)
      options[:limit] = normalize_limit(options[:limit]) || @n_records
      create_result_set(@records.sort(keys, options))
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
      resolved_record = record
      @n_key_nested.times do
        return nil if resolved_record.nil?
        resolved_record = resolved_record.key
      end
      return nil if resolved_record.nil?
      while resolved_record.key.is_a?(Groonga::Record)
        resolved_record = resolved_record.key
      end
      instance = @klass.instantiate(resolved_record)
      instance.score = record.score if record.support_sub_records?
      instance
    end

    def compute_n_key_nested
      @n_key_nested = 0
      return unless @records.respond_to?(:domain)
      domain = @records.domain
      while domain.is_a?(Groonga::Table)
        @n_key_nested += 1
        domain = domain.domain
      end
    end

    def normalize_limit(limit)
      unless limit.blank?
        begin
          Integer(limit)
        rescue
          limit = nil
        end
      end
      limit || @default_limit
    end

    def normalize_page(page)
      if page.blank?
        1
      else
        begin
          Integer(page)
        rescue ArgumentError
          1
        end
      end
    end

    def normalize_sort_keys(keys)
      if keys.blank?
        [["_id", :ascending]]
      else
        keys
      end
    end

    def create_result_set(records)
      self.class.new(records, @klass,
                     :default_sort_keys => @default_sort_keys,
                     :default_limit => @default_limit,
                     :expression => @expression)
    end

    module PaginationProxy
      Groonga::Pagination.instance_methods.each do |method_name|
        define_method(method_name) do
          @records.send(method_name)
        end
      end

      # For kaminari.
      alias_method :num_pages, :n_pages
      alias_method :limit_value, :page_size
    end
  end
end
