module ActivityEvents
  module TransactionFormatting
    private

    def type
      I18n.t("activity.types.#{@transaction.category.expense? ? :expense : :income}")
    end

    def money(value)
      format("$%.2f", value.abs)
    end

    def description_with_category
      if @transaction.description.present?
        "#{@transaction.category.name}: #{@transaction.description}"
      else
        @transaction.category.name
      end
    end
  end
end
