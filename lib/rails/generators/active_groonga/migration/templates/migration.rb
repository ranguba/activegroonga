class <%= migration_class_name %> < ActiveGroonga::Migration
  def up
<%- if migration_action -%>
    change_table(:<%= table_name %>) do |table|
  <% columns.each do |column| -%>
    <%- if migration_action == "add" -%>
      table.<%= column.create_code %>
    <%- else -%>
      table.<%= column.remove_code %>
    <%- end -%>
  <%- end -%>
    end
<%- end -%>
  end

  def down
<%- if migration_action -%>
    change_table(:<%= table_name %>) do |table|
  <% columns.reverse.each do |column| -%>
    <%- if migration_action == "add" -%>
      table.<%= column.remove_code %>
    <%- else -%>
      table.<%= column.create_code %>
    <%- end -%>
  <%- end -%>
    end
<%- end -%>
  end
end
