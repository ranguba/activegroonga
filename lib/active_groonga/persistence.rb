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
  module Persistence
    def new_record?
      @new_record
    end

    def destroyed?
      @destroyed
    end

    def persisted?
      not (new_record? or destroyed?)
    end

    def save(options={})
      create_or_update
    end

    def save!(options={})
      create_or_update or raise(RecordNotSaved)
    end

    def delete
      table.delete(record_id) if persisted?
      @destroyed = true
      freeze
    end

    def destroy
      table.delete(record_id) if persisted?
      @destroyed = true
      freeze
    end

    def becomes(klass)
      became = klass.new
      became.instance_variable_set("@attributes", @attributes)
      became.instance_variable_set("@attributes_cache", @attributes_cache)
      became.instance_variable_set("@new_record", new_record?)
      became.instance_variable_set("@destroyed", destroyed?)
      became
    end

    def update_attribute(name, value)
      name = name.to_s
      send("#{name}=", value)
      save(:validate => false)
    end

    def update_attributes(attributes)
      self.attributes = attributes
      save
    end

    def update_attributes!(attributes)
      self.attributes = attributes
      save!
    end

    def reload
      if new_record?
        record = nil
      else
        record = table[record_id]
      end
      reload_attributes(record)
      @attributes_cache = {}
      self
    end

    private
    def create_or_update
      success = new_record? ? create : update
      success != false
    end

    def create
      attributes = {}
      @attributes.each do |key, value|
        if value.is_a?(Base)
          value.save if value.new_record?
          value = value.id
        end
        attributes[key] = value
      end
      if table.support_key?
        record = table.add(key, attributes)
      else
        record = table.add(attributes)
      end
      record["created_at"] = Time.now if record.have_column?("created_at")
      reload_attributes(record)
      @new_record = false
      true
    end

    def update
      record = self.class.table[@id]
      @attributes.each do |key, value|
        if value.respond_to?(:record_id)
          value = value.record_id
        elsif value.is_a?(Hash) and value["id"]
          value = value["id"]
        end
        record[key] = value
      end
      record["updated_at"] = Time.now if record.have_column?("updated_at")
      true
    end

    def initial_attributes
      attributes = {}
      self.class.table.columns.each do |column|
        next if column.index_column?
        attributes[column.local_name] = nil
      end
      attributes
    end

    def extract_attributes(record)
      attributes = {}
      if record.support_key?
        attributes["key"] = record.key
      else
        attributes["id"] = record.id
      end
      record.columns.each do |column|
        next if column.is_a?(Groonga::IndexColumn)
        value = record[column.local_name]
        if value and column.reference_column?
          value_class = column.range.name.camelize.singularize.constantize
          value = value_class.instantiate(value)
        end
        attributes[column.local_name] = value
      end
      attributes
    end

    def reload_attributes(record=nil)
      if record.nil?
        @attributes = initial_attributes
      else
        @attributes = extract_attributes(record)
      end
      @id = @attributes.delete("id")
      @key = @attributes.delete("key")
    end
  end
end
