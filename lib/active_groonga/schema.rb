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

require 'active_groonga/migrator'

module ActiveGroonga
  class Schema
    class << self
      def define(options={}, &block)
        new(options).define(&block)
      end

      def dump(options={})
        new(options).dump
      end
    end

    def initialize(options={})
      @options = (options || {}).dup
      @version = @options.delete(:version)
      context = @options.delete(:context) || Base.context
      @schema = Groonga::Schema.new(:context => context)
    end

    def define(&block)
      yield(@schema)
      @schema.define
    end

    def dump(output=nil)
      return_string = false
      if output.nil?
        output = StringIO.new
        return_string = true
      end
      output << "ActiveGroonga::Schema.define(:version => 0) do |schema|\n"
      output << "  schema.instance_eval do\n"
      @schema.dump.each_line do |line|
        if /^\s*$/ =~ line
          output << line
        else
          output << "    #{line}"
        end
      end
      output << "  end\n"
      output << "end\n"
      if return_string
        output.string
      else
        output
      end
    end
  end
end
