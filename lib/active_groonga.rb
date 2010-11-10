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

require 'pathname'

require 'active_model'

base_dir = Pathname(__FILE__).dirname
rroonga_dir = (base_dir + "../../groonga").expand_path
if rroonga_dir.exist?
  $LOAD_PATH.unshift(rroonga_dir + "ext" + "groonga")
  $LOAD_PATH.unshift(rroonga_dir + "lib")
end

require 'groonga'

module ActiveGroonga
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :VERSION

    autoload :Error

    autoload :Base
    autoload :Schema

    autoload :AttributeMethods
  end
end

I18n.load_path << (base_dir + '/active_groonga/locale/en.yml').to_s
