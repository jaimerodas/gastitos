require "test_helper"

class ActivityLoggerTest < ActiveSupport::TestCase
  setup do
    @tmpdir = Dir.mktmpdir
    ActivityLogger.log_dir = Pathname.new(@tmpdir)
    @user = users(:jaime)
    @log_path = ActivityLogger.log_path(@user)
  end

  teardown do
    FileUtils.remove_entry(@tmpdir)
    ActivityLogger.log_dir = Rails.root.join("storage", "activity_logs")
  end

  test "log creates the file and appends a formatted line" do
    ActivityLogger.log(@user, "Test message")

    assert @log_path.exist?
    lines = File.readlines(@log_path, chomp: true)
    assert_equal 1, lines.size
    assert_match(/\A\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] Test message\z/, lines.first)
  end

  test "log appends multiple lines" do
    ActivityLogger.log(@user, "First")
    ActivityLogger.log(@user, "Second")

    lines = File.readlines(@log_path, chomp: true)
    assert_equal 2, lines.size
    assert_match(/First/, lines.first)
    assert_match(/Second/, lines.last)
  end

  test "recent_lines returns last N lines in reverse order" do
    5.times { |i| ActivityLogger.log(@user, "Line #{i}") }

    lines = ActivityLogger.recent_lines(@user, 3)
    assert_equal 3, lines.size
    assert_match(/Line 4/, lines.first)
    assert_match(/Line 2/, lines.last)
  end

  test "recent_lines returns empty array when no log file exists" do
    assert_equal [], ActivityLogger.recent_lines(@user)
  end

  test "log_transaction_created logs expense with details" do
    txn = transactions(:lunch)
    ActivityLogger.log_transaction_created(@user, txn)

    lines = ActivityLogger.recent_lines(@user)
    assert lines.any? { |l| l.include?("Creó gasto") && l.include?("$12.50") && l.include?("Food") && l.include?("2026-03-28") && l.include?("Tacos") && l.include?("ID: #{txn.id}") }
  end

  test "log_transaction_created logs income with details" do
    txn = transactions(:paycheck)
    ActivityLogger.log_transaction_created(@user, txn)

    lines = ActivityLogger.recent_lines(@user)
    assert lines.any? { |l| l.include?("Creó ingreso") && l.include?("$1000.00") && l.include?("Salary") }
  end

  test "log_transaction_updated logs changes" do
    txn = transactions(:lunch)
    changes = { "amount" => [ -12.50, -20.00 ], "description" => [ "Tacos", "Burritos" ] }
    ActivityLogger.log_transaction_updated(@user, txn, changes)

    lines = ActivityLogger.recent_lines(@user)
    assert lines.any? { |l| l.include?("Editó gasto ##{txn.id}") && l.include?("monto $12.50→$20.00") && l.include?("descripción \"Tacos\"→\"Burritos\"") }
  end

  test "log_transaction_updated logs date change" do
    txn = transactions(:lunch)
    changes = { "date" => [ Date.new(2026, 3, 28), Date.new(2026, 3, 29) ] }
    ActivityLogger.log_transaction_updated(@user, txn, changes)

    lines = ActivityLogger.recent_lines(@user)
    assert lines.any? { |l| l.include?("fecha 2026-03-28→2026-03-29") }
  end

  test "log_transaction_updated logs category change" do
    txn = transactions(:lunch)
    changes = { "category_id" => [ categories(:rideshare).id, categories(:food).id ] }
    ActivityLogger.log_transaction_updated(@user, txn, changes)

    lines = ActivityLogger.recent_lines(@user)
    assert lines.any? { |l| l.include?("categoría Rideshare→Food") }
  end

  test "log_transaction_destroyed logs expense details" do
    txn = transactions(:lunch)
    ActivityLogger.log_transaction_destroyed(@user, txn)

    lines = ActivityLogger.recent_lines(@user)
    assert lines.any? { |l| l.include?("Eliminó gasto") && l.include?("$12.50") && l.include?("Food") && l.include?("2026-03-28") }
  end

  test "log_login logs session start" do
    ActivityLogger.log_login(@user)

    lines = ActivityLogger.recent_lines(@user)
    assert lines.any? { |l| l.include?("Inició sesión") }
  end

  test "log_logout logs session end" do
    ActivityLogger.log_logout(@user)

    lines = ActivityLogger.recent_lines(@user)
    assert lines.any? { |l| l.include?("Cerró sesión") }
  end

  test "log_password_reset_requested logs request" do
    ActivityLogger.log_password_reset_requested(@user)

    lines = ActivityLogger.recent_lines(@user)
    assert lines.any? { |l| l.include?("Solicitó restablecimiento de contraseña") }
  end

  test "log_password_reset_completed logs completion" do
    ActivityLogger.log_password_reset_completed(@user)

    lines = ActivityLogger.recent_lines(@user)
    assert lines.any? { |l| l.include?("Restableció su contraseña") }
  end
end
