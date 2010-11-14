class <%= migration_class_name %> < ActiveGroonga::Migration
  def up
    create_table(:<%= table_name %>) do |table|
<% attributes.each do |attribute| -%>
      table.<%= attribute.type %>(:<%= attribute.name %>)
<% end -%>
<% if options[:timestamps] -%>
      table.timestamps
<% end -%>
    end
  end

  def down
    remoe_table(:<%= table_name %>)
  end
end
