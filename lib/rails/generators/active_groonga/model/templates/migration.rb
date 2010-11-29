class <%= migration_class_name %> < ActiveGroonga::Migration
  def up
    <%= create_table_code %> do |table|
<% columns.each do |column| -%>
      table.<%= column.create_code %>
<% end -%>
<% if options[:timestamps] -%>
      table.timestamps
<% end -%>
    end
  end

  def down
    <%= remove_table_code %>
  end
end
