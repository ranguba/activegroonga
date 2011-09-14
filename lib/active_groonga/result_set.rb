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

    # Paginates the result set.
    #
    # @overload paginate(sort_keys, options={})
    #   @param [Array<Array<String, Symbol>>] sort_keys
    #     The array of sort key for paginating. Each sort
    #     key is an array of sort key column name and order.
    #   @option options [Integer] :size The page size.
    #     {Base.limit} is used as the default value.
    #   @option options [Integer] :page The target page.
    #     The page is 1 origin not 0 origin. 1 is used as
    #     the default value.
    #   @return [ResultSet] paginated result set.
    #
    #   @example
    #     result_set = User.all
    #     # Paginates by sorting by "name" column value in
    #     # ascending order. The paginated result set has
    #     # less than or equal 10 records. And the returned
    #     # page is user requested page. If user doesn't
    #     # specify page, the first page is returned.
    #     result_set.paginate([["name", :ascending]],
    #                         :size => 10,
    #                         :page => param[:page])
    #
    # @overload paginate(options={})
    #   @option options [Integer] :size The page size.
    #     {Base.limit} is used as the default value.
    #   @option options [Integer] :page The target page.
    #     1 is used as the default value.
    #   @return [ResultSet] paginated result set.
    #
    #   @example
    #     # The default sort keys.
    #     User.sort_keys = [["name", :ascending]]
    #     result_set = User.all
    #     # Paginates by sorting by "name" column value in
    #     # ascending order because it is the default sort
    #     # keys. The paginated result set has
    #     # less than or equal 10 records. And the returned
    #     # page is user requested page. If user doesn't
    #     # specify page, the first page is returned.
    #     result_set.paginate(:size => 10,
    #                         :page => param[:page])
    #
    #   {Base.sort_keys} is used as the sort keys.
    def paginate(sort_keys=nil, options={})
      if sort_keys.is_a?(Hash) and options.empty?
        options = sort_keys
        sort_keys = nil
      end
      options[:size] = normalize_limit(options[:size])
      options[:page] = normalize_page(options[:page])
      sort_keys = normalize_sort_keys(sort_keys)
      records = @records.paginate(sort_keys, options)
      set = create_result_set(records)
      set.extend(PaginationProxy)
      set
    end

    # Sorts the result set.
    #
    # @overload sort(keys, options={})
    #   @param [Array<Array<String, Symbol>>] keys
    #     The array of sort key for sort. Each sort
    #     key is an array of sort key column name and order.
    #   @option options [Integer] :limit The max number of records.
    #     {Base.limit} is used as the default value.
    #     If {Base.limit} is nil, all records are returned.
    #   @option options [Integer] :offset The record start offset.
    #     Offset is 0-origin not 1-origin.
    #     The default value is 0.
    #   @return [ResultSet] sorted result set.
    #
    #   @example
    #     result_set = User.all
    #     # Sorts by "name" column value in
    #     # ascending order. The sorted result set has
    #     # from the 5th records to the 14th records.
    #     result_set.paginate([["name", :ascending]],
    #                         :limit => 10,
    #                         :offset => 4)
    #
    # @overload sort(options={})
    #   @option options [Integer] :limit The max number of records.
    #     {Base.limit} is used as the default value.
    #     If {Base.limit} is nil, all records are returned.
    #   @option options [Integer] :offset The record start offset.
    #     Offset is 0-origin not 1-origin.
    #     The default value is 0.
    #   @return [ResultSet] sorted result set.
    #
    #   @example
    #     # The default sort keys.
    #     User.sort_keys = [["name", :ascending]]
    #     result_set = User.all
    #     # Sorts by "name" column value in
    #     # ascending order because it is the default sort
    #     # keys. The sorted result set has
    #     # from the 5th records to the 14th records.
    #     result_set.paginate(:limit => 10,
    #                         :offset => 4)
    #
    #   {Base.sort_keys} is used as the sort keys.
    def sort(keys=nil, options={})
      if keys.is_a?(Hash) and options.empty?
        options = keys
        keys = nil
      end
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

    # Returns whether this result set has records or not.
    #
    # @return [true, false] true if the result set has one
    #    or more records, false otherwise.
    def empty?
      records.empty?
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
      keys = @default_sort_keys if keys.blank?
      keys = [["_id", :ascending]] if keys.blank?
      keys
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
