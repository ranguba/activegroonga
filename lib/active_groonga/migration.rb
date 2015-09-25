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
  class Migration
    @@migrations = []
    class << self
      def inherited(sub_class)
        super
        @@migrations << sub_class
      end

      def migrations
        @@migrations
      end

      def migration_name
        name.split(/::/).last
      end
    end

    attr_reader :version, :path
    def initialize(version, path, schema)
      @version = version
      @path = path
      @schema = schema
    end

    def name
      self.class.migration_name
    end

    def migrate(direction)
      result = nil
      case direction
      when :up
        report("migrating")
      when :down
        report("reverting")
      end
      time = Benchmark.measure do
        result = send(direction)
      end
      case direction
      when :up
        report("migrated (%.4fs)" % time.real)
      when :down
        report("reverted (%.4fs)" % time.real)
      end
      result
    end

    private
    def report(message)
      relative_path = @path.relative_path_from(Rails.root)
      text = "#{@version} #{name} (#{relative_path}): #{message}"
      rest_length = [0, 75 - text.length].max
      puts("== #{text} #{'=' * rest_length}")
    end

    def root_directory
      case
      when defined? Rails
        Rails.root
      when defined? Padrino
        Padrino.root
      else
        Pathname.pwd
      end
    end

    def method_missing(name, *args, &block)
      if @schema.respond_to?(name)
        @schema.send(name, *args, &block)
      else
        super
      end
    end
  end
end
