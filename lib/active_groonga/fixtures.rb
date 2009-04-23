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

module ActiveGroonga
  module TestFixtures
    class << self
      def included(base)
        base.class_eval do
          alias_method_chain :setup_fixtures, :active_groonga
          alias_method_chain :teardown_fixtures, :active_groonga
        end
      end
    end

    def setup_fixtures_with_active_groonga
      setup_fixtures_without_active_groonga

      @fixture_cache ||= {}
      @@already_loaded_fixtures ||= {}

      load_active_groonga_fixtures
    end

    def teardown_fixtures_with_active_groonga
      teardown_fixtures_without_active_groonga
    end

    def load_active_groonga_fixtures
      @loaded_fixtures ||= {}
      fixtures = Fixtures.create_fixtures(fixture_path, fixture_table_names, fixture_class_names) do
        ConnectionMock.new
      end
      unless fixtures.nil?
        if fixtures.instance_of?(Fixtures)
          @loaded_fixtures[fixtures.name] = fixtures
        else
          fixtures.each { |f| @loaded_fixtures[f.name] = f }
        end
      end
    end

    class ConnectionMock
      def initialize
        @last_quoted_table_name = nil
      end

      def disable_referential_integrity
        yield
      end

      def transaction(options=nil)
        yield
      end

      def quote_table_name(table_name)
        @last_quoted_table_name = Base.groonga_table_name(table_name)
        table_name
      end

      def delete(sql, name=nil)
        if @last_quoted_table_name
          Base.context[@last_quoted_table_name].truncate
        end
      end

      def insert_fixture(fixture, table_name)
        table = Base.context[Base.groonga_table_name(table_name)]
        record = table.add

        row = fixture.to_hash

        fixture.each do |key, value|
          record[key] = value
        end

        row[fixture.model_class.primary_key] = record.id
      end
    end
  end
end
