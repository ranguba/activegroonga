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
    class ModelGenerator < Base
      argument(:attributes,
               :type => :array,
               :default => [],
               :banner => "field:type field:type")

      check_class_collision

      class_option(:migration, :type => :boolean)
      class_option(:timestamps, :type => :boolean)
      class_option(:parent,
                   :type => :string,
                   :desc => "The parent class for the generated model")

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

      hook_for :test_framework

      protected
      def parent_class_name
        options[:parent] || "ActiveGroonga::Base"
      end
    end
  end
end
