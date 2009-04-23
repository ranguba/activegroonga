class CreateUsers < ActiveGroonga::Migration
  def self.up
    create_table :users do |t|
      t.string :original_id
      t.string :name

      t.timestamps

      t.index :original_id
      t.index :name
    end
  end

  def self.down
    drop_table :users
  end
end
