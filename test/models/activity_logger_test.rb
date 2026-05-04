require "test_helper"

class ActivityLoggerTest < ActiveSupport::TestCase
  class FakeStore
    attr_reader :appended

    def initialize
      @appended = Hash.new { |h, k| h[k] = [] }
    end

    def append(user, line)
      @appended[user.id] << line
    end

    def recent(user, count = 50)
      @appended[user.id].last(count).reverse
    end

    def read_all(user)
      (@appended[user.id].join("\n") + "\n")
    end
  end

  setup do
    @user = users(:jaime)
    @store = FakeStore.new
    fixed_time = Time.zone.local(2026, 5, 3, 14, 30, 45)
    @logger = ActivityLogger.new(store: @store, now: -> { fixed_time })
  end

  test "log timestamps the event message and forwards to the store" do
    @logger.log(@user, :login)
    assert_equal [ "[2026-05-03 14:30:45] #{I18n.t('activity.login')}" ], @store.appended[@user.id]
  end

  test "log raises KeyError for unknown event keys" do
    assert_raises(KeyError) { @logger.log(@user, :nonexistent) }
  end

  test "log skips writing when the event message is blank" do
    txn = transactions(:lunch)
    txn.save!  # no formattable changes
    @logger.log(@user, :transaction_updated, txn)
    assert_empty @store.appended[@user.id]
  end

  test "log forwards positional args to the event constructor" do
    txn = transactions(:lunch)
    @logger.log(@user, :transaction_created, txn)
    assert_match(/Creó/, @store.appended[@user.id].first)
    assert_match(/##{txn.id}|ID: #{txn.id}/, @store.appended[@user.id].first)
  end

  test "recent returns store output in reverse order" do
    @logger.log(@user, :login)
    @logger.log(@user, :logout)
    lines = @logger.recent(@user, 2)
    assert_equal 2, lines.size
    assert_match(/#{Regexp.escape(I18n.t('activity.logout'))}/, lines.first)
    assert_match(/#{Regexp.escape(I18n.t('activity.login'))}/, lines.last)
  end

  test "download_for returns full store contents" do
    @logger.log(@user, :login)
    @logger.log(@user, :logout)
    assert_match(/#{Regexp.escape(I18n.t('activity.login'))}/, @logger.download_for(@user))
    assert_match(/#{Regexp.escape(I18n.t('activity.logout'))}/, @logger.download_for(@user))
  end

  test "log isolates output per user" do
    other = users(:sofia)
    @logger.log(@user, :login)
    @logger.log(other, :logout)
    assert_match(/#{Regexp.escape(I18n.t('activity.login'))}/, @logger.recent(@user).first)
    assert_match(/#{Regexp.escape(I18n.t('activity.logout'))}/, @logger.recent(other).first)
    assert_no_match(/#{Regexp.escape(I18n.t('activity.logout'))}/, @logger.recent(@user).join)
  end

  test "default constructor wires up a FileStore" do
    logger = ActivityLogger.new
    assert_instance_of ActivityLogger::FileStore, logger.instance_variable_get(:@store)
  end

  test "EVENTS registry covers every ActivityEvents class" do
    expected = ActivityEvents.constants.filter_map do |c|
      klass = ActivityEvents.const_get(c)
      klass if klass.is_a?(Class)
    end.to_set
    assert_equal expected, ActivityLogger::EVENTS.values.to_set
  end

  # -- Class-method facade --

  test "class-level log writes through to the default store" do
    @tmpdir = Dir.mktmpdir
    original = ActivityLogger::FileStore.default_dir
    ActivityLogger::FileStore.default_dir = Pathname.new(@tmpdir)

    ActivityLogger.log(@user, :login)
    assert_match(/#{Regexp.escape(I18n.t('activity.login'))}/, ActivityLogger.recent(@user).first)
    assert_match(/#{Regexp.escape(I18n.t('activity.login'))}/, ActivityLogger.download_for(@user))
  ensure
    FileUtils.remove_entry(@tmpdir) if @tmpdir
    ActivityLogger::FileStore.default_dir = original
  end
end
