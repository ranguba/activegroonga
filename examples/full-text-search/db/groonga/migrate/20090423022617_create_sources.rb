class CreateSources < ActiveGroonga::Migration
  def self.up
    create_table :sources do |t|
      t.string :name
      t.text :description
      t.string :url

      t.timestamps
    end
  end

  def self.down
    drop_table :sources
  end
end
