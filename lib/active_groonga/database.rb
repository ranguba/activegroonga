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

require 'fileutils'

module ActiveGroonga
  class Database
    def initialize(path)
      @path = path
      @database = nil
    end

    def ensure_available
      return if @database
      if @path.exist?
        @database = Groonga::Database.open(@path.to_s,
                                           :context => Base.context)
      else
        @database = Groonga::Database.create(:path => @path.to_s,
                                             :context => Base.context)
      end
    end

    def remove
      return if @database.nil?
      @database.remove
      @database = nil
    end
  end
end
