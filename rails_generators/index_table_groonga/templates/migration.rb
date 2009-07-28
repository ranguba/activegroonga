class <%= migration_name %> < ActiveGroonga::Migration
  def self.up
    create_table :<%= table_name %>, :default_tokenizer => <%= default_tokenizer_name %> do |t|
    end
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
