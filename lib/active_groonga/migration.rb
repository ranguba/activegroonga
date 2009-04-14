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
  class Migration < ActiveRecord::Migration
    class << self
      undef_method :connection

      def method_missing(method, *arguments, &block)
        arg_list = arguments.map(&:inspect) * ', '

        say_with_time "#{method}(#{arg_list})" do
          unless arguments.empty? || method == :execute
            arguments[0] = Migrator.proper_table_name(arguments.first)
          end
          Schema.send(method, *arguments, &block)
        end
      end
    end
  end

  class Migrator < ActiveRecord::Migrator
    class << self
      def schema_migrations_table_name
        Base.table_name_prefix + 'schema_migrations' + Base.table_name_suffix
      end

      def groonga_schema_migrations_table_name
        Base.groonga_metadata_table_name(schema_migrations_table_name)
      end

      def get_all_versions
        table = Base.context[groonga_schema_migrations_table_name]
        table.records.collect {|record| record.key.to_i}.sort
      end

      def current_version
        table = Base.context[groonga_schema_migrations_table_name]
        if table.nil?
          0
        else
          get_all_versions.max || 0
        end
      end

      def proper_table_name(name)
        begin
          name.table_name
        rescue
          "#{Base.table_name_prefix}#{name}#{Base.table_name_suffix}"
        end
      end
    end

    def initialize(direction, migrations_path, target_version = nil)
      Schema.initialize_schema_management_tables
      @direction, @migrations_path, @target_version = direction, migrations_path, target_version
      FileUtils.mkdir_p(@migrations_path) unless File.exist?(@migrations_path)
    end

    def migrate
      current = migrations.detect { |m| m.version == current_version }
      target = migrations.detect { |m| m.version == @target_version }

      if target.nil? && !@target_version.nil? && @target_version > 0
        raise UnknownMigrationVersionError.new(@target_version)
      end
      
      start = up? ? 0 : (migrations.index(current) || 0)
      finish = migrations.index(target) || migrations.size - 1
      runnable = migrations[start..finish]
      
      # skip the last migration if we're headed down, but not ALL the way down
      runnable.pop if down? && !target.nil?
      
      runnable.each do |migration|
        Base.logger.info "Migrating to #{migration.name} (#{migration.version})"

        # On our way up, we skip migrating the ones we've already migrated
        next if up? && migrated.include?(migration.version.to_i)

        # On our way down, we skip reverting the ones we've never migrated
        if down? && !migrated.include?(migration.version.to_i)
          migration.announce 'never migrated, skipping'; migration.write
          next
        end

        begin
          migration.migrate(@direction)
          record_version_state_after_migrating(migration.version)
        rescue => e
          raise StandardError, "An error has occurred, all later migrations canceled:\n\n#{e}", e.backtrace
        end
      end
    end

    private
    def record_version_state_after_migrating(version)
      table_name = self.class.groonga_schema_migrations_table_name
      table = Base.context[table_name]

      @migrated_versions ||= []
      if down?
        @migrated_versions.delete(version.to_i)
        table.records.each do |record|
          record.delete if record.key == version.to_s
        end
      else
        @migrated_versions.push(version.to_i).sort!
        table.add(version.to_s)
      end
    end
  end
end
