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
  module Callbacks
    extend ActiveSupport::Concern

    included do
      extend ActiveModel::Callbacks
      include ActiveModel::Validations::Callbacks

      define_model_callbacks :initialize, :find, :only => :after
      define_model_callbacks :save, :create, :update, :destory
    end

    def destroy #:nodoc:
      run_callbacks(:destory) {super}
    end

    private
    def create_or_update #:nodoc:
      run_callbacks(:save) {super}
    end

    def create #:nodoc:
      run_callbacks(:create) {super}
    end

    def update #:nodoc:
      run_callbacks(:update) {super}
    end
  end
end
