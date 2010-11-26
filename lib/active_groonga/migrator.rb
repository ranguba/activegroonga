# Copyright (C) 2009-2010  Kouhei Sutou <kou@clear-code.com>
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
  class DuplicateMigrationVersionError < Error #:nodoc:
    attr_reader :version, :path
    def initialize(version, path)
      @version = version
      @path = path
      super("duplicated migration version exists: #{version}: <#{@path}>")
    end
  end

  class MigrationEntry
    attr_reader :version, :path
    def initialize(migration, version, path)
      @migration = migration
      @version = version
      @path = path
    end

    def name
      @migration.migration_name
    end

    def migrate(direction, schema)
      migration = @migration.new(@version, @path, schema)
      migration.migrate(direction)
    end
  end

  class SchemaManagementTable
    TABLE_NAME = "schema_migrations"

    def initialize
      ensure_table
      @table = Base.context[TABLE_NAME]
    end

    def current_version
      @current_version ||= (migrated_versions.last || [0]).first
    end

    def migrated_versions
      @migrated_versions ||= @table.collect do |record|
        [record.key, record.migrated_at]
      end.sort_by do |version, migrated_at|
        version
      end
    end

    def update_version(version)
      @table.add(version, :migrated_at => Time.now)
      clear_cache
    end

    def remove_version(version)
      @table[version].delete
      clear_cache
    end

    private
    def ensure_table
      Schema.define do |schema|
        schema.create_table(TABLE_NAME,
                            :type => :hash,
                            :key_type => "UInt64") do |table|
          table.time("migrated_at")
        end
      end
    end

    def clear_cache
      @current_version = nil
      @migrated_versions = nil
    end
  end

  class Migrator
    def initialize(direction, migrations_path)
      @direction = direction
      @migrations_path = migrations_path
      unless @migrations_path.is_a?(Pathname)
        @migrations_path = Pathanme(@migrations_path)
      end
    end

    def migrate(target_version=nil)
      _current_version = current_version
      migration_entries.each do |entry|
        if up?
          next if entry.version <= _current_version
        else
          next if entry.version > _current_version
        end
        Base.logger.info("Migrating to #{entry.name} (#{entry.version})")
        active_groonga_schema = Schema.new(:context => Base.context)
        active_groonga_schema.define do |schema|
          entry.migrate(@direction, schema)
        end
        if up?
          management_table.update_version(entry.version)
        else
          management_table.remove_version(entry.version)
        end
        break if entry.version == target_version
      end
    end

    def up?
      @direction == :up
    end

    def down?
      @direction == :down
    end

    def current_version
      management_table.current_version
    end

    def migrated_versions
      management_table.migrated_versions
    end

    def management_table
      @management_table ||= SchemaManagementTable.new
    end

    private
    def migration_entries
      @migration_entries ||= collect_migration_entries
    end

    def collect_migration_entries
      migration_entries = []
      Pathname.glob(@migrations_path + "[0-9]*_[a-z]*.rb").each do |path|
        if /\A([0-9]+)_([_a-z0-9]+)\.rb\z/ =~ path.basename.to_s
          version = $1.to_i
        else
          next
        end

        if migration_entries.find {|entry| entry.version == version}
          raise DuplicateMigrationVersionError.new(version, path)
        end

        migrations_before = Migration.migrations.dup
        load(path, true)
        defined_migrations = Migration.migrations - migrations_before
        defined_migrations.each do |migration|
          migration_entries << MigrationEntry.new(migration, version, path)
        end
      end

      migration_entries = migration_entries.sort_by(&:version)
      down? ? migration_entries.reverse : migration_entries
    end
  end
end
