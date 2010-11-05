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
  class Migrator
    MANAGEMENT_TABLE_NAME = "schema_migrations"

    def initialize
      ensure_table
    end

    private
    def ensure_table
      groonga_table_name = Base.groonga_metadata_table_name(MANAGEMENT_TABLE_NAME)
      if Base.context[groonga_table_name].nil?
          table_file = File.join(Base.database_directory,
                                 "#{groonga_table_name}.groonga")
          Groonga::Hash.create(:name => groonga_table_name,
                               :path => table_file,
                               :key_type => "ShortText")
      end
    end
  end
end
