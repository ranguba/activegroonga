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
  module AttributeMethods
    def self.included(base)
      base.module_eval do
        include ActiveRecord::AttributeMethods
        extend AttributeMethods::ClassMethods
      end
    end

    module ClassMethods
      def instance_method_already_implemented?(method_name)
        method_name = method_name.to_s
        return true if method_name =~ /^id(=$|\?$|$)/
        @_defined_class_methods         ||= ancestors.first(ancestors.index(ActiveGroonga::Base)).sum([]) { |m| m.public_instance_methods(false) | m.private_instance_methods(false) | m.protected_instance_methods(false) }.map(&:to_s).to_set
        @@_defined_activegroonga_methods ||= (ActiveGroonga::Base.public_instance_methods(false) | ActiveGroonga::Base.private_instance_methods(false) | ActiveGroonga::Base.protected_instance_methods(false)).map(&:to_s).to_set
        raise DangerousAttributeError, "#{method_name} is defined by ActiveGroonga" if @@_defined_activegroonga_methods.include?(method_name)
        @_defined_class_methods.include?(method_name)
      end
    end
  end
end
