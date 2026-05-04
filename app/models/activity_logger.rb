class ActivityLogger
  TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S".freeze

  EVENTS = {
    login:                    ActivityEvents::Login,
    logout:                   ActivityEvents::Logout,
    password_reset_requested: ActivityEvents::PasswordResetRequested,
    password_reset_completed: ActivityEvents::PasswordResetCompleted,
    transaction_created:      ActivityEvents::TransactionCreated,
    transaction_destroyed:    ActivityEvents::TransactionDestroyed,
    transaction_updated:      ActivityEvents::TransactionUpdated
  }.freeze

  def self.log(user, event, *args) = new.log(user, event, *args)
  def self.recent(user, count = 50) = new.recent(user, count)
  def self.download_for(user) = new.download_for(user)

  def initialize(store: FileStore.new, now: -> { Time.current })
    @store = store
    @now = now
  end

  def log(user, event, *args)
    klass = EVENTS.fetch(event)
    message = klass.new(*args).message
    return if message.blank?

    @store.append(user, "[#{@now.call.strftime(TIMESTAMP_FORMAT)}] #{message}")
  end

  def recent(user, count = 50)
    @store.recent(user, count)
  end

  def download_for(user)
    @store.read_all(user)
  end
end
