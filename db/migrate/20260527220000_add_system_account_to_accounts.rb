class AddSystemAccountToAccounts < ActiveRecord::Migration[8.0]
  RESERVED_USERNAMES = %w[metaverse-system admin_demo].freeze

  def up
    add_column :accounts, :system_account, :boolean, default: false, null: false
    add_index :accounts, :system_account

    return unless table_exists?(:accounts)

    RESERVED_USERNAMES.each do |username|
      execute <<~SQL.squish
        UPDATE accounts
        SET system_account = TRUE, admin = FALSE
        WHERE username = #{connection.quote(username)}
      SQL
    end
  end

  def down
    remove_index :accounts, :system_account
    remove_column :accounts, :system_account
  end
end
