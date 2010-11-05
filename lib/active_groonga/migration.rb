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
    def initialize(version, name)
      @version = version
      @name = name
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
      text = "#{@version} #{@name}: #{message}"
      rest_length = [0, 75 - text.length].max
      puts("== #{text} #{'=' * rest_length}")
    end
  end
end
