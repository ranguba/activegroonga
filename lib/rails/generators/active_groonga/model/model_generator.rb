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

require 'rails/generators/active_groonga'
require 'rails/generators/active_groonga/migration/column'

module ActiveGroonga
  module Generators
    class ModelGenerator < Base
      argument(:columns, :type => :array, :default => [],
               :banner => "name:type[:option:option] name:type[:option:option]")

      check_class_collision

      class_option(:migration, :type => :boolean)
      class_option(:timestamps, :type => :boolean)
      class_option(:parent,
                   :type => :string,
                   :desc => "The parent class for the generated model")

      def initialize(args, *options)
        super
        @key = nil
        @table_type = nil
        @key_normalize = false
        @default_tokenizer = nil
        parse_columns!
      end

      def create_migration_file
        return unless options[:migration] && options[:parent].nil?
        migration_template("migration.rb",
                           "db/groonga/migrate/create_#{table_name}.rb")
      end

      def create_model_file
        template('model.rb',
                 File.join("app/models", class_path, "#{file_name}.rb"))
      end

      def create_module_file
        return if class_path.empty?
        if behavior == :invoke
          template('module.rb', "app/models/#{class_path.join('/')}.rb")
        end
      end

      def create_table_code
        code = "create_table(:#{table_name}"
        options = []
        options << ":type => :#{@table_type}" if @table_type
        options << ":key_type => \"#{@key}\"" if @key
        options << ":key_normalize => #{@key_normalize}" if @key_normalize
        options << ":default_tokenizer => \"#{@tokenizer}\"" if @tokenizer
        code << ", #{options.join(', ')}" unless options.empty?
        code << ")"
        code
      end

      def remove_table_code
        "remove_table(:#{table_name})"
      end

      hook_for :test_framework

      protected
      def parent_class_name
        options[:parent] || "ActiveGroonga::Base"
      end

      private
      def parse_columns! #:nodoc:
        parsed_columns = []
        (columns || []).each do |key_value|
          name, type, *options = key_value.split(':')
          case name
          when "key"
            @key = Groonga::Schema.normalize_type(type)
            @table_type = options.find do |option|
              ["hash", "patricia_trie"].include?(option)
            end
            key_normalize = options.include?("normalize")
            @table_type ||= @key_normalize ? "patricia_trie" : "hash"
            if @table_type == "patricia_trie"
              @key_normalize = key_normalize
            end
            tokenizer_label_index = options.index("tokenizer")
            if tokenizer_label_index
              tokenizer = options[tokenizer_label_index + 1]
              @tokenizer = Groonga::Schema.normalize_type(tokenizer)
            end
          else
            parsed_columns << Column.new(name, type, options)
          end
        end
        self.columns = parsed_columns
      end
    end
  end
end
