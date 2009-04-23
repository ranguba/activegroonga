class CreateDocuments < ActiveGroonga::Migration
  def self.up
    create_table :documents do |t|
      t.string :title
      t.text :content
      t.string :version
      t.references :user
      t.references :source

      t.timestamps
    end
  end

  def self.down
    drop_table :documents
  end
end
