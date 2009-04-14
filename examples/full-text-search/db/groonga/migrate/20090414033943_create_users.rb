class CreateUsers < ActiveGroonga::Migration
  def self.up
    create_table :users do |t|
      t.integer :original_id
      t.string :name

      t.timestamps
    end

    add_index(:users, :original_id)
    add_index(:users, :name)
  end

  def self.down
    drop_table :users
  end
end
