require "test_helper"

class MonthlyPeriodWindowTest < ActiveSupport::TestCase
  setup do
    MonthlyPeriod.create!(month: 11, year: 2025, starting_balance: 0)
    MonthlyPeriod.create!(month: 12, year: 2025, starting_balance: 0)
    MonthlyPeriod.create!(month: 1, year: 2026, starting_balance: 0)
    MonthlyPeriod.create!(month: 4, year: 2026, starting_balance: 0)
    MonthlyPeriod.create!(month: 5, year: 2026, starting_balance: 0)
    # fixture monthly_periods(:march_2026) provides 2026-03
  end

  test "default window shows the most recent periods, oldest first" do
    window = MonthlyPeriodWindow.new
    assert_equal [ "2026-03", "2026-04", "2026-05" ], window.periods.map(&:to_param)
  end

  test "default window's older_anchor points past the window" do
    window = MonthlyPeriodWindow.new
    assert_equal "2026-01", window.older_anchor
  end

  test "default window has no newer_anchor" do
    window = MonthlyPeriodWindow.new
    assert_nil window.newer_anchor
  end

  test "default window has no anchor" do
    window = MonthlyPeriodWindow.new
    assert_nil window.anchor
  end

  test "default window size is 3" do
    window = MonthlyPeriodWindow.new
    assert_equal 3, window.size
    assert_equal "3", window.size_param
  end

  test "default window is not all" do
    window = MonthlyPeriodWindow.new
    assert_not window.all?
  end

  test "anchored window shows the periods ending at the anchor" do
    window = MonthlyPeriodWindow.new(size: "3", anchor: "2026-01")
    assert_equal [ "2025-11", "2025-12", "2026-01" ], window.periods.map(&:to_param)
  end

  test "anchored window at the oldest periods has no older_anchor" do
    window = MonthlyPeriodWindow.new(size: "3", anchor: "2026-01")
    assert_nil window.older_anchor
  end

  test "anchored window's newer_anchor points to the newest window" do
    window = MonthlyPeriodWindow.new(size: "3", anchor: "2026-01")
    assert_equal "2026-05", window.newer_anchor
  end

  test "anchored window's anchor matches the requested anchor" do
    window = MonthlyPeriodWindow.new(size: "3", anchor: "2026-01")
    assert_equal "2026-01", window.anchor
  end

  test "window anchored off a page boundary still shows a full window" do
    window = MonthlyPeriodWindow.new(anchor: "2026-04")
    assert_equal [ "2026-01", "2026-03", "2026-04" ], window.periods.map(&:to_param)
  end

  test "window anchored off a page boundary has correct older_anchor" do
    window = MonthlyPeriodWindow.new(anchor: "2026-04")
    assert_equal "2025-12", window.older_anchor
  end

  test "window anchored off a page boundary clamps newer_anchor to the newest window" do
    window = MonthlyPeriodWindow.new(anchor: "2026-04")
    assert_equal "2026-05", window.newer_anchor
  end

  test "size 6 shows all six periods with no paging" do
    window = MonthlyPeriodWindow.new(size: "6")
    assert_equal [ "2025-11", "2025-12", "2026-01", "2026-03", "2026-04", "2026-05" ], window.periods.map(&:to_param)
    assert_nil window.older_anchor
    assert_nil window.newer_anchor
  end

  test "size 12 with only six periods shows all six" do
    window = MonthlyPeriodWindow.new(size: "12")
    assert_equal [ "2025-11", "2025-12", "2026-01", "2026-03", "2026-04", "2026-05" ], window.periods.map(&:to_param)
  end

  test "size todos shows all periods oldest first regardless of anchor" do
    window = MonthlyPeriodWindow.new(size: "todos", anchor: "2026-01")
    assert_equal [ "2025-11", "2025-12", "2026-01", "2026-03", "2026-04", "2026-05" ], window.periods.map(&:to_param)
  end

  test "size todos reports all?" do
    window = MonthlyPeriodWindow.new(size: "todos", anchor: "2026-01")
    assert window.all?
  end

  test "size todos has nil size and todos size_param" do
    window = MonthlyPeriodWindow.new(size: "todos", anchor: "2026-01")
    assert_nil window.size
    assert_equal "todos", window.size_param
  end

  test "size todos has no anchors" do
    window = MonthlyPeriodWindow.new(size: "todos", anchor: "2026-01")
    assert_nil window.anchor
    assert_nil window.older_anchor
    assert_nil window.newer_anchor
  end

  test "invalid size falls back to the default size" do
    assert_equal 3, MonthlyPeriodWindow.new(size: "7").size
    assert_equal 3, MonthlyPeriodWindow.new(size: "abc").size
    assert_equal 3, MonthlyPeriodWindow.new(size: nil).size
  end

  test "invalid anchor falls back to the default window" do
    default_periods = MonthlyPeriodWindow.new.periods.map(&:to_param)
    assert_equal default_periods, MonthlyPeriodWindow.new(anchor: "2099-01").periods.map(&:to_param)
    assert_equal default_periods, MonthlyPeriodWindow.new(anchor: "foo").periods.map(&:to_param)
  end

  test "empty when there are no periods" do
    MonthlyPeriod.delete_all
    window = MonthlyPeriodWindow.new
    assert window.empty?
    assert_equal [], window.periods
    assert_nil window.anchor
    assert_nil window.older_anchor
    assert_nil window.newer_anchor
  end

  test "uses exactly one query" do
    window = MonthlyPeriodWindow.new
    assert_queries_count(1) do
      window.periods
      window.older_anchor
      window.newer_anchor
      window.anchor
    end
  end
end
