module ActivityEvents
  class TransactionUpdated
    include TransactionFormatting

    FORMATTABLE = %i[amount category date description].freeze

    def initialize(transaction)
      @transaction = transaction
      @changes = build_summary
    end

    def message
      return nil if @changes.empty?

      I18n.t("activity.transaction_updated",
             type: type,
             id: @transaction.id,
             details: details)
    end

    private

    def build_summary
      previous = @transaction.previous_changes
      summary = {}
      summary[:amount]      = previous["amount"]      if previous.key?("amount")
      summary[:date]        = previous["date"]        if previous.key?("date")
      summary[:description] = previous["description"] if previous.key?("description")
      if previous.key?("category_id")
        old_id, _ = previous["category_id"]
        summary[:category] = [ Category.find(old_id).name, @transaction.category.name ]
      end
      summary
    end

    def details
      @changes.filter_map { |k, (old, new)| format_change(k, old, new) if FORMATTABLE.include?(k) }
              .join(", ")
    end

    def format_change(key, old, new)
      I18n.t("activity.changes.#{key}", old: present(key, old), new: present(key, new))
    end

    def present(key, value)
      key == :amount ? money(value) : value
    end
  end
end
