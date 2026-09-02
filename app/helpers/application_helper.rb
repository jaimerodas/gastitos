module ApplicationHelper
  def amount_class(amount)
    amount.negative? ? "amount-expense" : "amount-income"
  end

  def amount_cell(amount, classes)
    if amount.zero?
      tag.td("—", class: "#{classes} zero")
    else
      tag.td(number_to_currency(amount), class: classes)
    end
  end

  def month_run_label(dates)
    names = [ dates.first, dates.last ].map { |date| I18n.t("date.month_names")[date.month].downcase }
    names.uniq.join("–")
  end
end
