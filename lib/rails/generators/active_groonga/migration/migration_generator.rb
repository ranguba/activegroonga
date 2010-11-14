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

module ActiveGroonga
  module Generators
    class MigrationGenerator < Base #:nodoc:
      argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"

      def create_migration_file
        set_local_assigns!
        migration_template "migration.rb", "db/groonga/migrate/#{file_name}.rb"
      end

      protected
      attr_reader :migration_action
      def set_local_assigns!
        if file_name =~ /^(add|remove)_.*_(?:to|from)_(.*)/
          @migration_action = $1
          @table_name       = $2.pluralize
        end
      end
    end
  end
end
