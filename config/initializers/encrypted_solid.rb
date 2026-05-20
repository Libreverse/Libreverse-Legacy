# Apply Active Record Encryption to SolidCache and SolidCable data.
# This ensures cached values and ActionCable payloads are stored encrypted
# at rest, mirroring the protection we added for Rodauth-related tables.

module EncryptionHelper
  def self.column?(model_class, column_name)
    return false unless model_class.respond_to?(:table_exists?)

    # Check if database exists before checking table existence
    begin
      # SQLite3Adapter doesn't have current_database method
      model_class.connection.current_database unless model_class.connection.is_a?(ActiveRecord::ConnectionAdapters::SQLite3Adapter)
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
      return false
    end

    begin
      return false unless model_class.table_exists?
    rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished, SQLite3::BusyException
      return false
    end

    begin
      model_class.columns_hash.key?(column_name.to_s)
    rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished, SQLite3::BusyException
      false
    end
  end
end

Rails.application.config.to_prepare do
  # Encrypt SolidCache entries (value column contains cached object)
  if defined?(SolidCache::Entry) && EncryptionHelper.column?(SolidCache::Entry, :value)
    SolidCache::Entry.class_eval do
      # Randomized encryption is fine – we never query by value contents
      encrypts :value
    end
  end

  # Encrypt SolidCable messages (payload column contains serialized data)
  if defined?(SolidCable::Message) && EncryptionHelper.column?(SolidCable::Message, :payload)
    SolidCable::Message.class_eval do
      encrypts :payload
    end
  end

  # Encrypt SolidQueue job arguments and concurrency keys
  if defined?(SolidQueue::Job)
    SolidQueue::Job.class_eval do
      encrypts :arguments if EncryptionHelper.column?(self, :arguments)
      encrypts :concurrency_key if EncryptionHelper.column?(self, :concurrency_key)
    end
  end

  # Encrypt concurrency_key on blocked executions if present
  if defined?(SolidQueue::BlockedExecution)
    SolidQueue::BlockedExecution.class_eval do
      encrypts :concurrency_key if EncryptionHelper.column?(self, :concurrency_key)
    end
  end

  # Encrypt process metadata
  if defined?(SolidQueue::Process)
    SolidQueue::Process.class_eval do
      encrypts :metadata if EncryptionHelper.column?(self, :metadata)
    end
  end

  # Encrypt SolidQueue recurring task arguments
  if defined?(SolidQueue::RecurringTask)
    SolidQueue::RecurringTask.class_eval do
      encrypts :arguments if EncryptionHelper.column?(self, :arguments)
    end
  end

  # Encrypt ActiveRecord session store data if present
  if Object.const_defined?(:Session)
    Session.class_eval do
      encrypts :data if EncryptionHelper.column?(self, :data)
    end
  end
end
