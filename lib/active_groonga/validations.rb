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

module ActiveGroonga
  class RecordInvalid < Error
    attr_reader :record
    def initialize(record)
      @record = record
      errors = @record.errors.full_messages.join(", ")
      super(I18n.t("activegroonga.errors.messages.record_invalid",
                   :errors => errors))
    end
  end

  module Validations
    extend ActiveSupport::Concern
    include ActiveModel::Validations

    included do
      validates_presence_of(:key,
                            :on => :create,
                            :if => lambda {|record| record.table.support_key?})
    end

    module ClassMethods
      def create!(attributes=nil, &block)
        if attributes.is_a?(Array)
          attributes.collect do |nested_attributes|
            create!(nested_attributes, &block)
          end
        else
          object = new(attributes)
          yield(object) if block_given?
          object.save!
          object
        end
      end
    end

    def save(options={})
      validate(options) ? super : false
    end

    def save!(options={})
      validate(options) ? super : raise(RecordInvalid.new(self))
    end

    def valid?(context=nil)
      context ||= (new_record? ? :create : :update)
      valid = super(context)
      errors.empty? and valid
    end

    private
    def validate(options={})
      if options[:validate] == false
        true
      else
        valid?(options[:context])
      end
    end
  end
end
