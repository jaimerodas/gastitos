class ActivityLogger
  TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S".freeze

  EVENTS = {
    login:                    -> { I18n.t("activity.login") },
    logout:                   -> { I18n.t("activity.logout") },
    password_reset_requested: -> { I18n.t("activity.password_reset_requested") },
    password_reset_completed: -> { I18n.t("activity.password_reset_completed") },
    transaction_created:      ->(txn) { ActivityEvents::TransactionEvent.new(txn, "activity.transaction_created").message },
    transaction_destroyed:    ->(txn) { ActivityEvents::TransactionEvent.new(txn, "activity.transaction_destroyed").message },
    transaction_updated:      ->(txn) { ActivityEvents::TransactionUpdated.new(txn).message }
  }.freeze

  def self.log(user, event, *args) = new.log(user, event, *args)
  def self.recent(user, count = 50) = new.recent(user, count)
  def self.download_for(user) = new.download_for(user)

  def initialize(store: FileStore.new)
    @store = store
  end

  def log(user, event, *args)
    message = EVENTS.fetch(event).call(*args)
    return if message.blank?

    @store.append(user, "[#{Time.current.strftime(TIMESTAMP_FORMAT)}] #{message}")
  end

  def recent(user, count = 50)
    @store.recent(user, count)
  end

  def download_for(user)
    @store.read_all(user)
  end
end
