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

require 'rubygems'
require 'active_support'
require 'active_record'

base_dir = File.dirname(__FILE__)
ruby_groonga_dir = File.join(base_dir, "..", "..", "groonga")
ruby_groonga_dir = File.expand_path(ruby_groonga_dir)
if File.exist?(ruby_groonga_dir)
  $LOAD_PATH.unshift(File.join(ruby_groonga_dir, "src"))
  $LOAD_PATH.unshift(File.join(ruby_groonga_dir, "src", "lib"))
end
require 'groonga'

module ActiveGroonga
  def self.load_all!
    [Base]
  end

  autoload :VERSION, 'active_groonga/version'

  autoload :ActiveGroongaError, 'active_groonga/base'
  autoload :ConnectionNotEstablished, 'active_groonga/base'

  autoload :Aggregations, 'active_groonga/aggregations'
  autoload :AssociationPreload, 'active_groonga/association_preload'
  autoload :Associations, 'active_groonga/associations'
  autoload :AttributeMethods, 'active_groonga/attribute_methods'
  autoload :AutosaveAssociation, 'active_groonga/autosave_association'
  autoload :Base, 'active_groonga/base'
  autoload :Batches, 'active_groonga/batches'
  autoload :Calculations, 'active_groonga/calculations'
  autoload :Callbacks, 'active_groonga/callbacks'
  autoload :Dirty, 'active_groonga/dirty'
  autoload :DynamicFinderMatch, 'active_groonga/dynamic_finder_match'
  autoload :DynamicScopeMatch, 'active_groonga/dynamic_scope_match'
  autoload :Migration, 'active_groonga/migration'
  autoload :Migrator, 'active_groonga/migration'
  autoload :NamedScope, 'active_groonga/named_scope'
  autoload :NestedAttributes, 'active_groonga/nested_attributes'
  autoload :Observing, 'active_groonga/observer'
  autoload :QueryCache, 'active_groonga/query_cache'
  autoload :Reflection, 'active_groonga/reflection'
  autoload :Schema, 'active_groonga/schema'
  autoload :SchemaDumper, 'active_groonga/schema_dumper'
  autoload :Serialization, 'active_groonga/serialization'
  autoload :SessionStore, 'active_groonga/session_store'
  autoload :TestCase, 'active_groonga/test_case'
  autoload :Timestamp, 'active_groonga/timestamp'
  autoload :Transactions, 'active_groonga/transactions'
  autoload :Validations, 'active_groonga/validations'

  module Locking
    autoload :Optimistic, 'active_groonga/locking/optimistic'
    autoload :Pessimistic, 'active_groonga/locking/pessimistic'
  end
end

I18n.load_path << File.dirname(__FILE__) + '/active_groonga/locale/en.yml'
