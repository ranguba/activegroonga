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

# This library includes ActiveRecord based codes temporary.
# Here is their copyright and license:
#
#   Copyright (c) 2004-2009 David Heinemeier Hansson
#
#   Permission is hereby granted, free of charge, to any person obtaining
#   a copy of this software and associated documentation files (the
#   "Software"), to deal in the Software without restriction, including
#   without limitation the rights to use, copy, modify, merge, publish,
#   distribute, sublicense, and/or sell copies of the Software, and to
#   permit persons to whom the Software is furnished to do so, subject to
#   the following conditions:
#
#   The above copyright notice and this permission notice shall be
#   included in all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#   LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#   OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#   WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module ActiveGroonga
  # Generic ActiveGroonga exception class.
  class ActiveGroongaError < StandardError
  end

  # Raised when ActiveGroonga cannot find record by given id or set of ids.
  class RecordNotFound < ActiveGroongaError
  end

  class Base
    ##
    # :singleton-method:
    # Accepts a logger conforming to the interface of Log4r or the default Ruby 1.8+ Logger class, which is then passed
    # on to any new database connections made and which can be retrieved on both a class and instance level by calling +logger+.
    cattr_accessor :logger, :instance_writer => false

    ##
    # :singleton-method:
    # Accessor for the name of the prefix string to prepend to every table name. So if set to "basecamp_", all
    # table names will be named like "basecamp_projects", "basecamp_people", etc. This is a convenient way of creating a namespace
    # for tables in a shared database. By default, the prefix is the empty string.
    cattr_accessor :table_name_prefix, :instance_writer => false
    @@table_name_prefix = ""

    ##
    # :singleton-method:
    # Works like +table_name_prefix+, but appends instead of prepends (set to "_basecamp" gives "projects_basecamp",
    # "people_basecamp"). By default, the suffix is the empty string.
    cattr_accessor :table_name_suffix, :instance_writer => false
    @@table_name_suffix = ""

    ##
    # :singleton-method:
    # Indicates whether table names should be the pluralized versions of the corresponding class names.
    # If true, the default table name for a Product class will be +products+. If false, it would just be +product+.
    # See table_name for the full rules on table/class naming. This is true, by default.
    cattr_accessor :pluralize_table_names, :instance_writer => false
    @@pluralize_table_names = true

    ##
    # :singleton-method:
    # Determines whether to use ANSI codes to colorize the logging statements committed by the connection adapter. These colors
    # make it much easier to overview things during debugging (when used through a reader like +tail+ and on a black background), but
    # may complicate matters if you use software like syslog. This is true, by default.
    cattr_accessor :colorize_logging, :instance_writer => false
    @@colorize_logging = true

    # Stores the default scope for the class
    class_inheritable_accessor :default_scoping, :instance_writer => false
    self.default_scoping = []

    class << self
      # If you have an attribute that needs to be saved to the database as an object, and retrieved as the same object,
      # then specify the name of that attribute using this method and it will be handled automatically.
      # The serialization is done through YAML. If +class_name+ is specified, the serialized object must be of that
      # class on retrieval or SerializationTypeMismatch will be raised.
      #
      # ==== Parameters
      #
      # * +attr_name+ - The field name that should be serialized.
      # * +class_name+ - Optional, class name that the object type should be equal to.
      #
      # ==== Example
      #   # Serialize a preferences attribute
      #   class User
      #     serialize :preferences
      #   end
      def serialize(attr_name, class_name = Object)
        serialized_attributes[attr_name.to_s] = class_name
      end

      # Returns a hash of all the attributes that have been specified for serialization as keys and their class restriction as values.
      def serialized_attributes
        read_inheritable_attribute(:attr_serialized) or write_inheritable_attribute(:attr_serialized, {})
      end

      # Guesses the table name (in forced lower-case) based on the name of the class in the inheritance hierarchy descending
      # directly from ActiveGroonga::Base. So if the hierarchy looks like: Reply < Message < ActiveGroonga::Base, then Message is used
      # to guess the table name even when called on Reply. The rules used to do the guess are handled by the Inflector class
      # in Active Support, which knows almost all common English inflections. You can add new inflections in config/initializers/inflections.rb.
      #
      # Nested classes are given table names prefixed by the singular form of
      # the parent's table name. Enclosing modules are not considered.
      #
      # ==== Examples
      #
      #   class Invoice < ActiveGroonga::Base; end;
      #   file                  class               table_name
      #   invoice.rb            Invoice             invoices
      #
      #   class Invoice < ActiveGroonga::Base; class Lineitem < ActiveGroonga::Base; end; end;
      #   file                  class               table_name
      #   invoice.rb            Invoice::Lineitem   invoice_lineitems
      #
      #   module Invoice; class Lineitem < ActiveGroonga::Base; end; end;
      #   file                  class               table_name
      #   invoice/lineitem.rb   Invoice::Lineitem   lineitems
      #
      # Additionally, the class-level +table_name_prefix+ is prepended and the
      # +table_name_suffix+ is appended.  So if you have "myapp_" as a prefix,
      # the table name guess for an Invoice class becomes "myapp_invoices".
      # Invoice::Lineitem becomes "myapp_invoice_lineitems".
      #
      # You can also overwrite this class method to allow for unguessable
      # links, such as a Mouse class with a link to a "mice" table. Example:
      #
      #   class Mouse < ActiveGroonga::Base
      #     set_table_name "mice"
      #   end
      def table_name
        reset_table_name
      end

      def reset_table_name #:nodoc:
        base = base_class

        name =
          # STI subclasses always use their superclass' table.
          unless self == base
            base.table_name
          else
            # Nested classes are prefixed with singular parent table name.
            if parent < ActiveGroonga::Base && !parent.abstract_class?
              contained = parent.table_name
              contained = contained.singularize if parent.pluralize_table_names
              contained << '_'
            end
            name = "#{table_name_prefix}#{contained}#{undecorated_table_name(base.name)}#{table_name_suffix}"
          end

        set_table_name(name)
        name
      end

      # Defines the column name for use with single table inheritance
      # -- can be set in subclasses like so: self.inheritance_column = "type_id"
      def inheritance_column
        @inheritance_column ||= "type".freeze
      end

      # Sets the table name to use to the given value, or (if the value
      # is nil or false) to the value returned by the given block.
      #
      #   class Project < ActiveGroonga::Base
      #     set_table_name "project"
      #   end
      def set_table_name(value = nil, &block)
        define_attr_method :table_name, value, &block
      end
      alias :table_name= :set_table_name

      # Turns the +table_name+ back into a class name following the reverse rules of +table_name+.
      def class_name(table_name = table_name) # :nodoc:
        # remove any prefix and/or suffix from the table name
        class_name = table_name[table_name_prefix.length..-(table_name_suffix.length + 1)].camelize
        class_name = class_name.singularize if pluralize_table_names
        class_name
      end

      # Indicates whether the table associated with this class exists
      def table_exists?
        not table.nil?
      end

      def primary_key
        "id"
      end

      # Returns an array of column objects for the table associated with this class.
      def columns
        @columns ||= table.columns.collect do |column|
          Column.new(column)
        end
      end

      # Returns a hash of column objects for the table associated with this class.
      def columns_hash
        @columns_hash ||= columns.inject({}) { |hash, column| hash[column.name] = column; hash }
      end

      # Returns an array of column names as strings.
      def column_names
        @column_names ||= columns.map { |column| column.name }
      end

      # Returns an array of column objects where the primary id, all columns ending in "_id" or "_count",
      # and columns used for single table inheritance have been removed.
      def content_columns
        @content_columns ||= columns.reject { |c| c.primary || c.name =~ /(_id|_count)$/ || c.name == inheritance_column }
      end

      # Returns a hash of all the methods added to query each of the columns in the table with the name of the method as the key
      # and true as the value. This makes it possible to do O(1) lookups in respond_to? to check if a given method for attribute
      # is available.
      def column_methods_hash #:nodoc:
        @dynamic_methods_hash ||= column_names.inject(Hash.new(false)) do |methods, attr|
          attr_name = attr.to_s
          methods[attr.to_sym]       = attr_name
          methods["#{attr}=".to_sym] = attr_name
          methods["#{attr}?".to_sym] = attr_name
          methods["#{attr}_before_type_cast".to_sym] = attr_name
          methods
        end
      end

      # Log and benchmark multiple statements in a single block. Example:
      #
      #   Project.benchmark("Creating project") do
      #     project = Project.create("name" => "stuff")
      #     project.create_manager("name" => "David")
      #     project.milestones << Milestone.find(:all)
      #   end
      #
      # The benchmark is only recorded if the current level of the logger is less than or equal to the <tt>log_level</tt>,
      # which makes it easy to include benchmarking statements in production software that will remain inexpensive because
      # the benchmark will only be conducted if the log level is low enough.
      #
      # The logging of the multiple statements is turned off unless <tt>use_silence</tt> is set to false.
      def benchmark(title, log_level=Logger::DEBUG, use_silence=true)
        if logger && logger.level <= log_level
          result = nil
          ms = Benchmark.ms { result = use_silence ? silence { yield } : yield }
          logger.add(log_level, '%s (%.1fms)' % [title, ms])
          result
        else
          yield
        end
      end

      # Overwrite the default class equality method to provide support for association proxies.
      def ===(object)
        object.is_a?(self)
      end

      # Returns the base AR subclass that this class descends from. If A
      # extends AR::Base, A.base_class will return A. If B descends from A
      # through some arbitrarily deep hierarchy, B.base_class will return A.
      def base_class
        class_of_active_groonga_descendant(self)
      end

      def find(*args)
        options = args.extract_options!
        validate_find_options(options)
        set_readonly_option!(options)

        case args.first
        when :first
          find_initial(options)
#         when :last
#           find_last(options)
        when :all
          find_every(options)
        else
          find_from_ids(args, options)
        end
      end

      def context
        @@context ||= Groonga::Context.default
      end

      def table
        @@table ||= context[table_name]
      end

      # Defines an "attribute" method (like +inheritance_column+ or
      # +table_name+). A new (class) method will be created with the
      # given name. If a value is specified, the new method will
      # return that value (as a string). Otherwise, the given block
      # will be used to compute the value of the method.
      #
      # The original method will be aliased, with the new name being
      # prefixed with "original_". This allows the new method to
      # access the original value.
      #
      # Example:
      #
      #   class A < ActiveRecord::Base
      #     define_attr_method :primary_key, "sysid"
      #     define_attr_method( :inheritance_column ) do
      #       original_inheritance_column + "_id"
      #     end
      #   end
      def define_attr_method(name, value=nil, &block)
        sing = class << self; self; end
        sing.send :alias_method, "original_#{name}", name
        if block_given?
          sing.send :define_method, name, &block
        else
          # use eval instead of a block to work around a memory leak in dev
          # mode in fcgi
          sing.class_eval "def #{name}; #{value.to_s.inspect}; end"
        end
      end

      protected
      # Retrieve the scope for the given method and optional key.
      def scope(method, key = nil) #:nodoc:
        if current_scoped_methods && (scope = current_scoped_methods[method])
          key ? scope[key] : scope
        end
      end

      def scoped_methods #:nodoc:
        Thread.current[:"#{self}_scoped_methods"] ||= default_scoping.dup
      end

      def current_scoped_methods #:nodoc:
        scoped_methods.last
      end

      # Returns the class descending directly from ActiveGroonga::Base or an
      # abstract class, if any, in the inheritance hierarchy.
      def class_of_active_groonga_descendant(klass)
        if klass.superclass == Base || klass.superclass.abstract_class?
          klass
        elsif klass.superclass.nil?
          raise ActiveGroongaError, "#{name} doesn't belong in a hierarchy descending from ActiveRecord"
        else
          class_of_active_record_descendant(klass.superclass)
        end
      end

      private
      def find_initial(options)
        options.update(:limit => 1)
        find_every(options).first
      end

      def find_every(options)
        include_associations = merge_includes(scope(:find, :include), options[:include])

        if include_associations.any? && references_eager_loaded_tables?(options)
          records = find_with_associations(options)
        else
          records = []
          table.open_cursor do |cursor|
            records = cursor.collect {|id| instantiate(id)}
          end
          if include_associations.any?
            preload_associations(records, include_associations)
          end
        end

        records.each {|record| record.readonly!} if options[:readonly]

        records
      end

      def find_from_ids(ids, options)
        expects_array = ids.first.kind_of?(Array)
        return ids.first if expects_array && ids.first.empty?

        ids = ids.flatten.compact.uniq

        case ids.size
        when 0
          raise RecordNotFound, "Couldn't find #{name} without an ID"
        when 1
          result = find_one(ids.first, options)
          expects_array ? [result] : result
        else
          find_some(ids, options)
        end
      end

      def find_one(id, options)
        result = context[id]
        if result.nil?
          raise RecordNotFound, "Couldn't find #{name} with ID=#{id}"
        end
        result
      end

      def find_some(ids, options)
        result = ids.collect do |id|
          context[id]
        end
        n_not_found_ids = result.count(nil)
        if n_not_found_ids.zero?
          result
        else
          raise RecordNotFound, "Couldn't find all #{name.pluralize} with IDs (#{ids}) (found #{result.compact.size} results, but was looking for #{ids.size})"
        end
      end

      def merge_includes(first, second)
        (safe_to_array(first) + safe_to_array(second)).uniq
      end

      # ugly. derived from Active Record. FIXME: remove it.
      def safe_to_array(o)
        case o
        when NilClass
          []
        when Array
          o
        else
          [o]
        end
      end

      VALID_FIND_OPTIONS = [:readonly]
      def validate_find_options(options)
        options.assert_valid_keys(VALID_FIND_OPTIONS)
      end

      def set_readonly_option!(options) #:nodoc:
        # Inherit :readonly from finder scope if set.  Otherwise,
        # if :joins is not blank then :readonly defaults to true.
        unless options.has_key?(:readonly)
          if scoped_readonly = scope(:find, :readonly)
            options[:readonly] = scoped_readonly
          elsif !options[:joins].blank? && !options[:select]
            options[:readonly] = true
          end
        end
      end

      # Guesses the table name, but does not decorate it with prefix and suffix information.
      def undecorated_table_name(class_name = base_class.name)
        table_name = class_name.to_s.demodulize.underscore
        table_name = table_name.pluralize if pluralize_table_names
        table_name
      end

      # Finder methods must instantiate through this method to work with the
      # single-table inheritance model that makes it possible to create
      # objects of different types from the same table.
      def instantiate(record)
        object =
          if subclass_name = record[inheritance_column]
            # No type given.
            if subclass_name.empty?
              allocate

            else
              # Ignore type if no column is present since it was probably
              # pulled in from a sloppy join.
              unless columns_hash.include?(inheritance_column)
                allocate

              else
                begin
                  compute_type(subclass_name).allocate
                rescue NameError
                  raise SubclassNotFound,
                    "The single-table inheritance mechanism failed to locate the subclass: '#{record[inheritance_column]}'. " +
                    "This error is raised because the column '#{inheritance_column}' is reserved for storing the class in case of inheritance. " +
                    "Please rename this column if you didn't intend it to be used for storing the inheritance class " +
                    "or overwrite #{self.to_s}.inheritance_column to use another column for that information."
                end
              end
            end
          else
            allocate
          end

        attributes = {}
        record.table.columns.each do |column|
          _, column_name = column.name.split(/\A#{record.table.name}\./, 2)
          attributes[column_name] = column[record.id]
        end
        object.instance_variable_set("@attributes", attributes)
        object.instance_variable_set("@attributes_cache", Hash.new)

        if object.respond_to_without_attributes?(:after_find)
          object.send(:callback, :after_find)
        end

        if object.respond_to_without_attributes?(:after_initialize)
          object.send(:callback, :after_initialize)
        end

        object
      end
    end

    include AttributeMethods
  end
end
