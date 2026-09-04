module ActivityEvents
  class TransactionUpdated
    include TransactionFormatting

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
      summary = @transaction.previous_changes.slice("amount", "date", "description").symbolize_keys
      if @transaction.previous_changes.key?("category_id")
        old_id, _ = @transaction.previous_changes["category_id"]
        summary[:category] = [ Category.find(old_id).name, @transaction.category.name ]
      end
      summary
    end

    def details
      @changes.map { |k, (old, new)| format_change(k, old, new) }.join(", ")
    end

    def format_change(key, old, new)
      I18n.t("activity.changes.#{key}", old: present(key, old), new: present(key, new))
    end

    def present(key, value)
      key == :amount ? money(value) : value
    end
  end
end
