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
  module Generators
    class Column #:nodoc:
      attr_accessor :name, :type, :options

      def initialize(name, type, options)
        if type.blank?
          message = "Missing type for attribute '#{name}'.\n" +
            "Example: '#{name}:short_text' where ShortText is the type."
          raise Thor::Error, message
        end
        @name, @type, @options = name, type.to_sym, options
      end

      def create_code
        if index?
          create_code_index
        else
          create_code_normal
        end
      end

      def remove_code
        if index?
          "remove_index(\"#{name}\")"
        else
          "remove_column(:#{name})"
        end
      end

      def vector?
        @options.include?("vector")
      end

      def with_section?
        @options.include?("with_section")
      end

      def with_weight?
        @options.include?("with_weight")
      end

      def with_position?
        @options.include?("with_position")
      end

      def index?
        @type == :index
      end

      def reference?
        @type == :reference
      end

      def reference_table_name
        @name.pluralize
      end

      private
      def create_code_index
        code = "index(\"#{name}\""
        options = []
        options << ":with_section => true" if with_section?
        options << ":with_weight => true" if with_weight?
        options << ":with_position => true" if with_position?
        unless options.empty?
          code << ", #{options.join(', ')}"
        end
        code << ")"
        code
      end

      def create_code_normal
        code = "#{type}(:#{name}"
        code << ", \"#{reference_table_name}\"" if reference?
        options = []
        options << ":type => :vector" if vector?
        unless options.empty?
          code << ", #{options.join(', ')}"
        end
        code << ")"
        code
      end
    end
  end
end
