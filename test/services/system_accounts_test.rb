# frozen_string_literal: true

require "test_helper"

class SystemAccountsTest < ActiveSupport::TestCase
  test "metaverse import owner is system account without admin or password" do
    account = SystemAccounts.find_or_create_metaverse_import_owner!

    assert_equal SystemAccounts::METAVERSE_IMPORT_OWNER, account.username
    assert account.system_account?
    assert_not account.admin?
    assert_nil account.password_hash
  end

  test "demo experiences owner is system account without admin" do
    account = SystemAccounts.find_or_create_demo_experiences_owner!

    assert_equal SystemAccounts::DEMO_EXPERIENCES_OWNER, account.username
    assert account.system_account?
    assert_not account.admin?
  end

  test "reconcile demotes mistaken admin flag on existing reserved account" do
    account = Account.create!(
      username: SystemAccounts::METAVERSE_IMPORT_OWNER,
      status: 2,
      admin: true,
      system_account: false,
      password_hash: "should-be-cleared"
    )

    reconciled = SystemAccounts.find_or_create_metaverse_import_owner!

    assert_equal account.id, reconciled.id
    assert reconciled.system_account?
    assert_not reconciled.admin?
    assert_nil reconciled.password_hash
  end

  test "reconcile clears admin column when system_account is already true" do
    account = Account.create!(
      username: SystemAccounts::DEMO_EXPERIENCES_OWNER,
      status: 2,
      admin: true,
      system_account: true
    )

    reconciled = SystemAccounts.find_or_create_demo_experiences_owner!

    assert_equal account.id, reconciled.id
    assert reconciled.system_account?
    assert_not reconciled.read_attribute(:admin)
    assert_not reconciled.admin?
  end

  test "admin? is false for system accounts even when admin column is true" do
    account = Account.create!(
      username: "system-admin-flag-test",
      status: 2,
      admin: true,
      system_account: true
    )

    assert account.system_account?
    assert_not account.admin?
  end

  test "unknown username raises" do
    assert_raises(ArgumentError) { SystemAccounts.find_or_create!("not-reserved") }
  end
end
