class MonthlyPeriodWindow
  SIZES = [ 3, 6, 12 ].freeze
  DEFAULT_SIZE = 3
  ALL = "todos"

  attr_reader :size

  def initialize(size: nil, anchor: nil)
    @size = normalize_size(size)
    @anchor_param = anchor
  end

  def size_param
    all? ? ALL : size.to_s
  end

  def all?
    size.nil?
  end

  def periods
    @periods ||= if all?
      all_periods.reverse
    else
      all_periods[start_index, size].to_a.reverse
    end
  end

  def empty?
    periods.empty?
  end

  def anchor
    return nil if all?
    start_index.zero? ? nil : all_periods[start_index]&.to_param
  end

  def older_anchor
    return nil if all?
    all_periods[start_index + size]&.to_param
  end

  def newer_anchor
    return nil if all?
    start_index.zero? ? nil : all_periods[[ start_index - size, 0 ].max].to_param
  end

  private

  def normalize_size(raw)
    return nil if raw.to_s == ALL
    SIZES.include?(raw.to_i) ? raw.to_i : DEFAULT_SIZE
  end

  def all_periods
    @all_periods ||= MonthlyPeriod.chronological.to_a
  end

  def start_index
    @start_index ||= all_periods.index { |p| p.to_param == @anchor_param } || 0
  end
end
