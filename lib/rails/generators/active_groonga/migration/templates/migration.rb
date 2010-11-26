class <%= migration_class_name %> < ActiveGroonga::Migration
  def up
<% attributes.each do |attribute| -%>
  <%- if migration_action -%>
    change_table(:<%= table_name %>) do |table|
    <%- if migration_action == "add" -%>
      table.<%= attribute.type %>(:<%= attribute.name %>)
    <%- else -%>
      table.remove_column(:<%= attribute.name %>)
    <%- end -%>
    end
  <%- end -%>
<%- end -%>
  end

  def down
<% attributes.reverse.each do |attribute| -%>
  <%- if migration_action -%>
    change_table(:<%= table_name %>) do |table|
    <%- if migration_action == "add" -%>
      table.remove_column(:<%= attribute.name %>)
    <%- else -%>
      table.<%= attribute.type %>(:<%= attribute.name %>)
    <%- end -%>
    end
  <%- end -%>
<%- end -%>
  end
end
