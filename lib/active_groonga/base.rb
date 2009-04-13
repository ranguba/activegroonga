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

require 'active_record/base'

module ActiveGroonga
  # Generic ActiveGroonga exception class.
  class ActiveGroongaError < StandardError
  end

  # Raised when ActiveGroonga cannot find record by given id or set of ids.
  class RecordNotFound < ActiveGroongaError
  end

  # Raised when database not specified (or configuration file <tt>config/groonga.yml</tt> misses database field).
  class DatabaseNotSpecified < ActiveGroongaError
  end

  class Base
    ##
    # :singleton-method:
    # Accepts a logger conforming to the interface of Log4r or the default Ruby 1.8+ Logger class, which is then passed
    # on to any new database connections made and which can be retrieved on both a class and instance level by calling +logger+.
    cattr_accessor :logger, :instance_writer => false

    ##
    # :singleton-method:
    # Contains the groonga configuration - as is typically stored in config/groonga.yml -
    # as a Hash.
    #
    # For example, the following groonga.yml...
    # 
    #   development:
    #     database: db/development.groonga
    #   
    #   production:
    #     adapter: groonga
    #     database: db/production.groonga
    #
    # ...would result in ActiveGroonga::Base.configurations to look like this:
    #
    #   {
    #      'development' => {
    #         'database' => 'db/development.groonga'
    #      },
    #      'production' => {
    #         'database' => 'db/production.groonga'
    #      }
    #   }
    cattr_accessor :configurations, :instance_writer => false
    @@configurations = {}

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

    # Determine whether to store the full constant name including namespace when using STI
    superclass_delegating_accessor :store_full_sti_class
    self.store_full_sti_class = false

    # Stores the default scope for the class
    class_inheritable_accessor :default_scoping, :instance_writer => false
    self.default_scoping = []

    ##
    # :singleton-method:
    # Specifies the format to use when dumping the database schema with Rails'
    # Rakefile.  If :sql, the schema is dumped as (potentially database-
    # specific) SQL statements.  If :ruby, the schema is dumped as an
    # ActiveRecord::Schema file which can be loaded into any database that
    # supports migrations.  Use :ruby if you want to have different database
    # adapters for, e.g., your development and test environments.
    cattr_accessor :schema_format , :instance_writer => false
    @@schema_format = :ruby

    cattr_accessor :database_directory, :instance_writer => false
    @@database_directory = nil

    class << self
      # Attributes named in this macro are protected from mass-assignment,
      # such as <tt>new(attributes)</tt>,
      # <tt>update_attributes(attributes)</tt>, or
      # <tt>attributes=(attributes)</tt>.
      #
      # Mass-assignment to these attributes will simply be ignored, to assign
      # to them you can use direct writer methods. This is meant to protect
      # sensitive attributes from being overwritten by malicious users
      # tampering with URLs or forms.
      #
      #   class Customer < ActiveRecord::Base
      #     attr_protected :credit_rating
      #   end
      #
      #   customer = Customer.new("name" => David, "credit_rating" => "Excellent")
      #   customer.credit_rating # => nil
      #   customer.attributes = { "description" => "Jolly fellow", "credit_rating" => "Superb" }
      #   customer.credit_rating # => nil
      #
      #   customer.credit_rating = "Average"
      #   customer.credit_rating # => "Average"
      #
      # To start from an all-closed default and enable attributes as needed,
      # have a look at +attr_accessible+.
      def attr_protected(*attributes)
        write_inheritable_attribute(:attr_protected, Set.new(attributes.map(&:to_s)) + (protected_attributes || []))
      end

      # Returns an array of all the attributes that have been protected from mass-assignment.
      def protected_attributes # :nodoc:
        read_inheritable_attribute(:attr_protected)
      end

      # Specifies a white list of model attributes that can be set via
      # mass-assignment, such as <tt>new(attributes)</tt>,
      # <tt>update_attributes(attributes)</tt>, or
      # <tt>attributes=(attributes)</tt>
      #
      # This is the opposite of the +attr_protected+ macro: Mass-assignment
      # will only set attributes in this list, to assign to the rest of
      # attributes you can use direct writer methods. This is meant to protect
      # sensitive attributes from being overwritten by malicious users
      # tampering with URLs or forms. If you'd rather start from an all-open
      # default and restrict attributes as needed, have a look at
      # +attr_protected+.
      #
      #   class Customer < ActiveRecord::Base
      #     attr_accessible :name, :nickname
      #   end
      #
      #   customer = Customer.new(:name => "David", :nickname => "Dave", :credit_rating => "Excellent")
      #   customer.credit_rating # => nil
      #   customer.attributes = { :name => "Jolly fellow", :credit_rating => "Superb" }
      #   customer.credit_rating # => nil
      #
      #   customer.credit_rating = "Average"
      #   customer.credit_rating # => "Average"
      def attr_accessible(*attributes)
        write_inheritable_attribute(:attr_accessible, Set.new(attributes.map(&:to_s)) + (accessible_attributes || []))
      end

      # Returns an array of all the attributes that have been made accessible to mass-assignment.
      def accessible_attributes # :nodoc:
        read_inheritable_attribute(:attr_accessible)
      end

      # Attributes listed as readonly can be set for a new record, but will be ignored in database updates afterwards.
      def attr_readonly(*attributes)
        write_inheritable_attribute(:attr_readonly, Set.new(attributes.map(&:to_s)) + (readonly_attributes || []))
      end

      # Returns an array of all the attributes that have been specified as readonly.
      def readonly_attributes
        read_inheritable_attribute(:attr_readonly)
      end


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

      # True if this isn't a concrete subclass needing a STI type condition.
      def descends_from_active_groonga?
        if superclass.abstract_class?
          superclass.descends_from_active_groonga?
        else
          superclass == Base || !columns_hash.include?(inheritance_column)
        end
      end

      # Returns a string like 'Post id:integer, title:string, body:text'
      def inspect
        if self == Base
          super
        elsif abstract_class?
          "#{super}(abstract)"
        elsif table_exists?
          attr_list = columns.map { |c| "#{c.name}: #{c.type}" } * ', '
          "#{super}(#{attr_list})"
        else
          "#{super}(Table doesn't exist)"
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

      # Set this to true if this is an abstract class (see <tt>abstract_class?</tt>).
      attr_accessor :abstract_class

      # Returns whether this class is a base AR class.  If A is a base class and
      # B descends from A, then B.base_class will return B.
      def abstract_class?
        defined?(@abstract_class) && @abstract_class == true
      end

      def find(*args)
        options = args.extract_options!
        validate_find_options(options)
        set_readonly_option!(options)

        case args.first
        when :first
          find_initial(options)
        when :last
          find_last(options)
        when :all
          find_every(options)
        else
          find_from_ids(args, options)
        end
      end

      # A convenience wrapper for <tt>find(:first, *args)</tt>. You can pass in all the
      # same arguments to this method as you can to <tt>find(:first)</tt>.
      def first(*args)
        find(:first, *args)
      end

      # A convenience wrapper for <tt>find(:last, *args)</tt>. You can pass in all the
      # same arguments to this method as you can to <tt>find(:last)</tt>.
      def last(*args)
        find(:last, *args)
      end

      # This is an alias for find(:all).  You can pass in all the same arguments to this method as you can
      # to find(:all)
      def all(*args)
        find(:all, *args)
      end

      def context
        Groonga::Context.default
      end

      def table
        context[table_name]
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

      def setup_database(spec=nil)
        case spec
        when nil
          raise DatabaseNotSpecified unless defined? RAILS_ENV
          setup_database(RAILS_ENV)
        when Symbol, String
          if configuration = configurations[spec.to_s]
            setup_database(configuration)
          else
            raise DatabaseNotSpecified, "#{spec} database is not configured"
          end
        else
          spec = spec.symbolize_keys
          unless spec.key?(:database)
            raise DatabaseNotSpecified, "groonga configuration does not specify database"
          end
          database_directory = spec[:database]

          Groonga::Context.default = nil
          Groonga::Context.default_options = {:encoding => spec[:encoding]}
          unless File.exist?(database_directory)
            FileUtils.mkdir_p(database_directory)
          end
          database_file = File.join(database_directory, "db")
          if File.exist?(database_file)
            @@database = Groonga::Database.new(database_file)
          else
            @@database = Groonga::Database.create(:path => database_file)
          end
          self.database_directory = database_directory
        end
      end

      def tables_directory
        directory = File.join(database_directory, "tables")
        FileUtils.mkdir_p(directory) unless File.exist?(directory)
        directory
      end

      def columns_directory(table_name)
        directory = File.join(tables_directory, table_name, "columns")
        FileUtils.mkdir_p(directory) unless File.exist?(directory)
        directory
      end

      def count
        table.size
      end

      private
      def find_initial(options)
        options.update(:limit => 1)
        find_every(options).first
      end

      def find_every(options)
        limit = options[:limit] ||= -1
        conditions = options[:conditions] || {}
        include_associations = merge_includes(scope(:find, :include), options[:include])

        if include_associations.any? && references_eager_loaded_tables?(options)
          records = find_with_associations(options)
        else
          records = []
          table.open_cursor do |cursor|
            cursor.each_with_index do |record, i|
              break if limit >= 0 and records.size >= limit
              next unless conditions.all? {|name, value| record[name] == value}
              records << instantiate(record)
            end
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
        result = instantiate(Groonga::Record.new(table, Integer(id)))
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

      VALID_FIND_OPTIONS = [:conditions, :readonly]
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

        object.instance_variable_set("@id", record.id)
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

      # Enables dynamic finders like <tt>find_by_user_name(user_name)</tt> and <tt>find_by_user_name_and_password(user_name, password)</tt>
      # that are turned into <tt>find(:first, :conditions => ["user_name = ?", user_name])</tt> and
      # <tt>find(:first, :conditions => ["user_name = ? AND password = ?", user_name, password])</tt> respectively. Also works for
      # <tt>find(:all)</tt> by using <tt>find_all_by_amount(50)</tt> that is turned into <tt>find(:all, :conditions => ["amount = ?", 50])</tt>.
      #
      # It's even possible to use all the additional parameters to +find+. For example, the full interface for +find_all_by_amount+
      # is actually <tt>find_all_by_amount(amount, options)</tt>.
      #
      # Also enables dynamic scopes like scoped_by_user_name(user_name) and scoped_by_user_name_and_password(user_name, password) that
      # are turned into scoped(:conditions => ["user_name = ?", user_name]) and scoped(:conditions => ["user_name = ? AND password = ?", user_name, password])
      # respectively.
      #
      # Each dynamic finder, scope or initializer/creator is also defined in the class after it is first invoked, so that future
      # attempts to use it do not run through method_missing.
      def method_missing(method_id, *arguments, &block)
        if match = ActiveRecord::DynamicFinderMatch.match(method_id)
          attribute_names = match.attribute_names
          super unless all_attributes_exists?(attribute_names)
          if match.finder?
            finder = match.finder
            bang = match.bang?
            # def self.find_by_login_and_activated(*args)
            #   options = args.extract_options!
            #   attributes = construct_attributes_from_arguments(
            #     [:login,:activated],
            #     args
            #   )
            #   finder_options = { :conditions => attributes }
            #   validate_find_options(options)
            #   set_readonly_option!(options)
            #
            #   if options[:conditions]
            #     with_scope(:find => finder_options) do
            #       find(:first, options)
            #     end
            #   else
            #     find(:first, options.merge(finder_options))
            #   end
            # end
            self.class_eval <<-EOC, __FILE__, __LINE__
              def self.#{method_id}(*args)
                options = args.extract_options!
                attributes = construct_attributes_from_arguments(
                  [:#{attribute_names.join(',:')}],
                  args
                )
                finder_options = { :conditions => attributes }
                validate_find_options(options)
                set_readonly_option!(options)

                #{'result = ' if bang}if options[:conditions]
                  with_scope(:find => finder_options) do
                    find(:#{finder}, options)
                  end
                else
                  find(:#{finder}, options.merge(finder_options))
                end
                #{'result || raise(RecordNotFound, "Couldn\'t find #{name} with #{attributes.to_a.collect {|pair| "#{pair.first} = #{pair.second}"}.join(\', \')}")' if bang}
              end
            EOC
            send(method_id, *arguments)
          elsif match.instantiator?
            instantiator = match.instantiator
            # def self.find_or_create_by_user_id(*args)
            #   guard_protected_attributes = false
            #
            #   if args[0].is_a?(Hash)
            #     guard_protected_attributes = true
            #     attributes = args[0].with_indifferent_access
            #     find_attributes = attributes.slice(*[:user_id])
            #   else
            #     find_attributes = attributes = construct_attributes_from_arguments([:user_id], args)
            #   end
            #
            #   options = { :conditions => find_attributes }
            #   set_readonly_option!(options)
            #
            #   record = find(:first, options)
            #
            #   if record.nil?
            #     record = self.new { |r| r.send(:attributes=, attributes, guard_protected_attributes) }
            #     yield(record) if block_given?
            #     record.save
            #     record
            #   else
            #     record
            #   end
            # end
            self.class_eval <<-EOC, __FILE__, __LINE__
              def self.#{method_id}(*args)
                guard_protected_attributes = false

                if args[0].is_a?(Hash)
                  guard_protected_attributes = true
                  attributes = args[0].with_indifferent_access
                  find_attributes = attributes.slice(*[:#{attribute_names.join(',:')}])
                else
                  find_attributes = attributes = construct_attributes_from_arguments([:#{attribute_names.join(',:')}], args)
                end

                options = { :conditions => find_attributes }
                set_readonly_option!(options)

                record = find(:first, options)

                if record.nil?
                  record = self.new { |r| r.send(:attributes=, attributes, guard_protected_attributes) }
                  #{'yield(record) if block_given?'}
                  #{'record.save' if instantiator == :create}
                  record
                else
                  record
                end
              end
            EOC
            send(method_id, *arguments, &block)
          end
        elsif match = ActiveRecord::DynamicScopeMatch.match(method_id)
          attribute_names = match.attribute_names
          super unless all_attributes_exists?(attribute_names)
          if match.scope?
            self.class_eval <<-EOC, __FILE__, __LINE__
              def self.#{method_id}(*args)                        # def self.scoped_by_user_name_and_password(*args)
                options = args.extract_options!                   #   options = args.extract_options!
                attributes = construct_attributes_from_arguments( #   attributes = construct_attributes_from_arguments(
                  [:#{attribute_names.join(',:')}], args          #     [:user_name, :password], args
                )                                                 #   )
                                                                  # 
                scoped(:conditions => attributes)                 #   scoped(:conditions => attributes)
              end                                                 # end
            EOC
            send(method_id, *arguments)
          end
        else
          super
        end
      end

      def construct_attributes_from_arguments(attribute_names, arguments)
        attributes = {}
        attribute_names.each_with_index { |name, idx| attributes[name] = arguments[idx] }
        attributes
      end

      # Similar in purpose to +expand_hash_conditions_for_aggregates+.
      def expand_attribute_names_for_aggregates(attribute_names)
        expanded_attribute_names = []
        attribute_names.each do |attribute_name|
          unless (aggregation = reflect_on_aggregation(attribute_name.to_sym)).nil?
            aggregate_mapping(aggregation).each do |field_attr, aggregate_attr|
              expanded_attribute_names << field_attr
            end
          else
            expanded_attribute_names << attribute_name
          end
        end
        expanded_attribute_names
      end

      def all_attributes_exists?(attribute_names)
        attribute_names = expand_attribute_names_for_aggregates(attribute_names)
        attribute_names.all? { |name| column_methods_hash.include?(name.to_sym) }
      end

      # Nest the type name in the same module as this class.
      # Bar is "MyApp::Business::Bar" relative to MyApp::Business::Foo
      def type_name_with_module(type_name)
        if store_full_sti_class
          type_name
        else
          (/^::/ =~ type_name) ? type_name : "#{parent.name}::#{type_name}"
        end
      end

      # Test whether the given method and optional key are scoped.
      def scoped?(method, key = nil) #:nodoc:
        if current_scoped_methods && (scope = current_scoped_methods[method])
          !key || !scope[key].nil?
        end
      end

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

      # Returns the class type of the record using the current module as a prefix. So descendants of
      # MyApp::Business::Account would appear as MyApp::Business::AccountSubclass.
      def compute_type(type_name)
        modularized_name = type_name_with_module(type_name)
        silence_warnings do
          begin
            class_eval(modularized_name, __FILE__, __LINE__)
          rescue NameError
            class_eval(type_name, __FILE__, __LINE__)
          end
        end
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
    end

    def initialize(attributes=nil)
      @id = nil
      @attributes = attributes_from_column_definition
      @attributes_cache = {}
      @new_record = true
      ensure_proper_type
      self.attributes = attributes unless attributes.nil?
      self.class.send(:scope, :create).each { |att,value| self.send("#{att}=", value) } if self.class.send(:scoped?, :create)
      result = yield self if block_given?
      callback(:after_initialize) if respond_to_without_attributes?(:after_initialize)
      result
    end

    # A model instance's primary key is always available as model.id
    # whether you name it the default 'id' or set it to something else.
    def id
      @id
    end

    # Returns a String, which Action Pack uses for constructing an URL to this
    # object. The default implementation returns this record's id as a String,
    # or nil if this record's unsaved.
    #
    # For example, suppose that you have a User model, and that you have a
    # <tt>map.resources :users</tt> route. Normally, +user_path+ will
    # construct a path with the user object's 'id' in it:
    #
    #   user = User.find_by_name('Phusion')
    #   user_path(user)  # => "/users/1"
    #
    # You can override +to_param+ in your model to make +user_path+ construct
    # a path using the user's name instead of the user's id:
    #
    #   class User < ActiveRecord::Base
    #     def to_param  # overridden
    #       name
    #     end
    #   end
    #   
    #   user = User.find_by_name('Phusion')
    #   user_path(user)  # => "/users/Phusion"
    def to_param
      # We can't use alias_method here, because method 'id' optimizes itself on the fly.
      (id = self.id) ? id.to_s : nil # Be sure to stringify the id for routes
    end

    # Sets the primary ID.
    def id=(value)
      @id = value
    end

    # Returns true if this object hasn't been saved yet -- that is, a record for the object doesn't exist yet; otherwise, returns false.
    def new_record?
      @new_record || false
    end

    # :call-seq:
    #   save(perform_validation = true)
    #
    # Saves the model.
    #
    # If the model is new a record gets created in the database, otherwise
    # the existing record gets updated.
    #
    # If +perform_validation+ is true validations run. If any of them fail
    # the action is cancelled and +save+ returns +false+. If the flag is
    # false validations are bypassed altogether. See
    # ActiveRecord::Validations for more information.
    #
    # There's a series of callbacks associated with +save+. If any of the
    # <tt>before_*</tt> callbacks return +false+ the action is cancelled and
    # +save+ returns +false+. See ActiveRecord::Callbacks for further
    # details.
    def save
      create_or_update
    end

    # Saves the model.
    #
    # If the model is new a record gets created in the database, otherwise
    # the existing record gets updated.
    #
    # With <tt>save!</tt> validations always run. If any of them fail
    # ActiveGroonga::RecordInvalid gets raised. See ActiveRecord::Validations
    # for more information.
    #
    # There's a series of callbacks associated with <tt>save!</tt>. If any of
    # the <tt>before_*</tt> callbacks return +false+ the action is cancelled
    # and <tt>save!</tt> raises ActiveGroonga::RecordNotSaved. See
    # ActiveRecord::Callbacks for further details.
    def save!
      create_or_update || raise(RecordNotSaved)
    end

    # Deletes the record in the database and freezes this instance to
    # reflect that no changes should be made (since they can't be
    # persisted). Returns the frozen instance.
    #
    # The row is simply removed with a SQL +DELETE+ statement on the
    # record's primary key, and no callbacks are executed.
    #
    # To enforce the object's +before_destroy+ and +after_destroy+
    # callbacks, Observer methods, or any <tt>:dependent</tt> association
    # options, use <tt>#destroy</tt>.
    def delete
      self.class.delete(id) unless new_record?
      freeze
    end

    # Deletes the record in the database and freezes this instance to reflect that no changes should
    # be made (since they can't be persisted).
    def destroy
      self.class.table.delete(id) unless new_record?
      freeze
    end

    # Updates a single attribute and saves the record without going through the normal validation procedure.
    # This is especially useful for boolean flags on existing records. The regular +update_attribute+ method
    # in Base is replaced with this when the validations module is mixed in, which it is by default.
    def update_attribute(name, value)
      send(name.to_s + '=', value)
      save(false)
    end

    # Updates all the attributes from the passed-in Hash and saves the record. If the object is invalid, the saving will
    # fail and false will be returned.
    def update_attributes(attributes)
      self.attributes = attributes
      save
    end

    # Updates an object just like Base.update_attributes but calls save! instead of save so an exception is raised if the record is invalid.
    def update_attributes!(attributes)
      self.attributes = attributes
      save!
    end

    # Returns the value of the attribute identified by <tt>attr_name</tt> after it has been typecast (for example,
    # "2004-12-12" in a data column is cast to a date object, like Date.new(2004, 12, 12)).
    # (Alias for the protected read_attribute method).
    def [](attr_name)
      read_attribute(attr_name)
    end

    # Updates the attribute identified by <tt>attr_name</tt> with the specified +value+.
    # (Alias for the protected write_attribute method).
    def []=(attr_name, value)
      write_attribute(attr_name, value)
    end

    # Allows you to set all the attributes at once by passing in a hash with keys
    # matching the attribute names (which again matches the column names).
    #
    # If +guard_protected_attributes+ is true (the default), then sensitive
    # attributes can be protected from this form of mass-assignment by using
    # the +attr_protected+ macro. Or you can alternatively specify which
    # attributes *can* be accessed with the +attr_accessible+ macro. Then all the
    # attributes not included in that won't be allowed to be mass-assigned.
    #
    #   class User < ActiveGroonga::Base
    #     attr_protected :is_admin
    #   end
    #   
    #   user = User.new
    #   user.attributes = { :username => 'Phusion', :is_admin => true }
    #   user.username   # => "Phusion"
    #   user.is_admin?  # => false
    #   
    #   user.send(:attributes=, { :username => 'Phusion', :is_admin => true }, false)
    #   user.is_admin?  # => true
    def attributes=(new_attributes, guard_protected_attributes = true)
      return if new_attributes.nil?
      attributes = new_attributes.dup
      attributes.stringify_keys!

      multi_parameter_attributes = []
      attributes = remove_attributes_protected_from_mass_assignment(attributes) if guard_protected_attributes

      attributes.each do |k, v|
        if k.include?("(")
          multi_parameter_attributes << [ k, v ]
        else
          respond_to?(:"#{k}=") ? send(:"#{k}=", v) : raise(UnknownAttributeError, "unknown attribute: #{k}")
        end
      end

      assign_multiparameter_attributes(multi_parameter_attributes)
    end

    # Returns a hash of all the attributes with their names as keys and the values of the attributes as values.
    def attributes
      self.attribute_names.inject({}) do |attrs, name|
        attrs[name] = read_attribute(name)
        attrs
      end
    end

    # Returns a hash of attributes before typecasting and deserialization.
    def attributes_before_type_cast
      self.attribute_names.inject({}) do |attrs, name|
        attrs[name] = read_attribute_before_type_cast(name)
        attrs
      end
    end

    # Returns an <tt>#inspect</tt>-like string for the value of the
    # attribute +attr_name+. String attributes are elided after 50
    # characters, and Date and Time attributes are returned in the
    # <tt>:db</tt> format. Other attributes return the value of
    # <tt>#inspect</tt> without modification.
    #
    #   person = Person.create!(:name => "David Heinemeier Hansson " * 3)
    #
    #   person.attribute_for_inspect(:name)
    #   # => '"David Heinemeier Hansson David Heinemeier Hansson D..."'
    #
    #   person.attribute_for_inspect(:created_at)
    #   # => '"2009-01-12 04:48:57"'
    def attribute_for_inspect(attr_name)
      value = read_attribute(attr_name)

      if value.is_a?(String) && value.length > 50
        "#{value[0..50]}...".inspect
      elsif value.is_a?(Date) || value.is_a?(Time)
        %("#{value.to_s(:db)}")
      else
        value.inspect
      end
    end

    # Returns true if the specified +attribute+ has been set by the user or by a database load and is neither
    # nil nor empty? (the latter only applies to objects that respond to empty?, most notably Strings).
    def attribute_present?(attribute)
      value = read_attribute(attribute)
      !value.blank?
    end

    # Returns true if the given attribute is in the attributes hash
    def has_attribute?(attr_name)
      @attributes.has_key?(attr_name.to_s)
    end

    # Returns an array of names for the attributes available on this object sorted alphabetically.
    def attribute_names
      @attributes.keys.sort
    end

    # Returns the column object for the named attribute.
    def column_for_attribute(name)
      self.class.columns_hash[name.to_s]
    end

    # Returns true if the +comparison_object+ is the same object, or is of the same type and has the same id.
    def ==(comparison_object)
      comparison_object.equal?(self) ||
        (comparison_object.instance_of?(self.class) &&
         comparison_object.id == id &&
         !comparison_object.new_record?)
    end

    # Delegates to ==
    def eql?(comparison_object)
      self == (comparison_object)
    end

    # Delegates to id in order to allow two records of the same type and id to work with something like:
    #   [ Person.find(1), Person.find(2), Person.find(3) ] & [ Person.find(1), Person.find(4) ] # => [ Person.find(1) ]
    def hash
      id.hash
    end

    # Freeze the attributes hash such that associations are still accessible, even on destroyed records.
    def freeze
      @attributes.freeze; self
    end

    # Returns +true+ if the attributes hash has been frozen.
    def frozen?
      @attributes.frozen?
    end

    # Returns +true+ if the record is read only. Records loaded through joins with piggy-back
    # attributes will be marked as read only since they cannot be saved.
    def readonly?
      defined?(@readonly) && @readonly == true
    end

    # Marks this record as read only.
    def readonly!
      @readonly = true
    end

    # Returns the contents of the record as a nicely formatted string.
    def inspect
      attributes_as_nice_string = self.class.column_names.collect { |name|
        if has_attribute?(name) || new_record?
          "#{name}: #{attribute_for_inspect(name)}"
        end
      }.compact.join(", ")
      "#<#{self.class} #{attributes_as_nice_string}>"
    end

    private
    def create_or_update
      raise ReadOnlyRecord if readonly?
      result = new_record? ? create : update
      result != false
    end

    # Updates the associated record with values matching those of the instance attributes.
    # Returns the number of affected rows.
    def update(attribute_names=@attributes.keys)
      attribute_names = remove_readonly_attributes(attribute_names)
      table = self.class.table
      attribute_names.each do |name|
        column = table.column(name)
        next if column.nil?
        column[id] =  read_attribute(name)
      end
    end

    # Creates a record with values matching those of the instance attributes
    # and returns its id.
    def create
      table = self.class.table
      record = table.add
      record.table.columns.each do |column|
        column = Column.new(column)
        record[column.name] = @attributes[column.name]
      end
      self.id = record.id
      @new_record = false
      id
    end

    # Sets the attribute used for single table inheritance to this class name if this is not the ActiveRecord::Base descendant.
    # Considering the hierarchy Reply < Message < ActiveRecord::Base, this makes it possible to do Reply.new without having to
    # set <tt>Reply[Reply.inheritance_column] = "Reply"</tt> yourself. No such attribute would be set for objects of the
    # Message class in that example.
    def ensure_proper_type
      unless self.class.descends_from_active_groonga?
        write_attribute(self.class.inheritance_column, self.class.sti_name)
      end
    end

    def remove_attributes_protected_from_mass_assignment(attributes)
      safe_attributes =
        if self.class.accessible_attributes.nil? && self.class.protected_attributes.nil?
          attributes.reject { |key, value| attributes_protected_by_default.include?(key.gsub(/\(.+/, "")) }
        elsif self.class.protected_attributes.nil?
          attributes.reject { |key, value| !self.class.accessible_attributes.include?(key.gsub(/\(.+/, "")) || attributes_protected_by_default.include?(key.gsub(/\(.+/, "")) }
        elsif self.class.accessible_attributes.nil?
          attributes.reject { |key, value| self.class.protected_attributes.include?(key.gsub(/\(.+/,"")) || attributes_protected_by_default.include?(key.gsub(/\(.+/, "")) }
        else
          raise "Declare either attr_protected or attr_accessible for #{self.class}, but not both."
        end

      removed_attributes = attributes.keys - safe_attributes.keys

      if removed_attributes.any?
        log_protected_attribute_removal(removed_attributes)
      end

      safe_attributes
    end

    # Removes attributes which have been marked as readonly.
    def remove_readonly_attributes(attributes)
      unless self.class.readonly_attributes.nil?
        attributes.delete_if { |key, value| self.class.readonly_attributes.include?(key.gsub(/\(.+/,"")) }
      else
        attributes
      end
    end

    def log_protected_attribute_removal(*attributes)
      logger.debug "WARNING: Can't mass-assign these protected attributes: #{attributes.join(', ')}"
    end

    # The primary key and inheritance column can never be set by mass-assignment for security reasons.
    def attributes_protected_by_default
      default = [ self.class.primary_key, self.class.inheritance_column ]
      default << 'id' unless self.class.primary_key.eql? 'id'
      default
    end

    # Initializes the attributes array with keys matching the columns from the linked table and
    # the values matching the corresponding default value of that column, so
    # that a new instance, or one populated from a passed-in Hash, still has all the attributes
    # that instances loaded from the database would.
    def attributes_from_column_definition
      self.class.columns.inject({}) do |attributes, column|
        attributes[column.name] = column.default
        attributes
      end
    end

    # Instantiates objects for all attribute classes that needs more than one constructor parameter. This is done
    # by calling new on the column type or aggregation type (through composed_of) object with these parameters.
    # So having the pairs written_on(1) = "2004", written_on(2) = "6", written_on(3) = "24", will instantiate
    # written_on (a date type) with Date.new("2004", "6", "24"). You can also specify a typecast character in the
    # parentheses to have the parameters typecasted before they're used in the constructor. Use i for Fixnum, f for Float,
    # s for String, and a for Array. If all the values for a given attribute are empty, the attribute will be set to nil.
    def assign_multiparameter_attributes(pairs)
      execute_callstack_for_multiparameter_attributes(
        extract_callstack_for_multiparameter_attributes(pairs)
      )
    end

    def execute_callstack_for_multiparameter_attributes(callstack)
      errors = []
      callstack.each do |name, values|
        klass = (self.class.reflect_on_aggregation(name.to_sym) || column_for_attribute(name)).klass
        if values.empty?
          send(name + "=", nil)
        else
          begin
            value = if Time == klass
              instantiate_time_object(name, values)
            elsif Date == klass
              begin
                Date.new(*values)
              rescue ArgumentError => ex # if Date.new raises an exception on an invalid date
                instantiate_time_object(name, values).to_date # we instantiate Time object and convert it back to a date thus using Time's logic in handling invalid dates
              end
            else
              klass.new(*values)
            end

            send(name + "=", value)
          rescue => ex
            errors << AttributeAssignmentError.new("error on assignment #{values.inspect} to #{name}", ex, name)
          end
        end
      end
      unless errors.empty?
        raise MultiparameterAssignmentErrors.new(errors), "#{errors.size} error(s) on assignment of multiparameter attributes"
      end
    end

    def extract_callstack_for_multiparameter_attributes(pairs)
      attributes = { }

      for pair in pairs
        multiparameter_name, value = pair
        attribute_name = multiparameter_name.split("(").first
        attributes[attribute_name] = [] unless attributes.include?(attribute_name)

        unless value.empty?
          attributes[attribute_name] <<
            [ find_parameter_position(multiparameter_name), type_cast_attribute_value(multiparameter_name, value) ]
        end
      end

      attributes.each { |name, values| attributes[name] = values.sort_by{ |v| v.first }.collect { |v| v.last } }
    end


    include Validations
    include AttributeMethods
    include Reflection, Associations
  end
end
