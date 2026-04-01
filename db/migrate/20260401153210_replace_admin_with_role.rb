class ReplaceAdminWithRole < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :role, :string, default: "viewer", null: false

    execute <<~SQL
      UPDATE users SET role = 'admin' WHERE admin = TRUE;
      UPDATE users SET role = 'editor' WHERE admin = FALSE AND approved = TRUE;
    SQL

    remove_column :users, :admin
  end

  def down
    add_column :users, :admin, :boolean, default: false, null: false

    execute <<~SQL
      UPDATE users SET admin = TRUE WHERE role = 'admin';
    SQL

    remove_column :users, :role
  end
end
