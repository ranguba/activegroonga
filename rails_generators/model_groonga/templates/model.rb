class <%= class_name %> < ActiveGroonga::Base
<% attributes.select(&:reference?).each do |attribute| -%>
  belongs_to :<%= attribute.name %>
<% end -%>
end
