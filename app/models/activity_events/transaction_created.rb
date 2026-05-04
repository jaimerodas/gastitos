module ActivityEvents
  class TransactionCreated
    include TransactionFormatting

    def initialize(transaction)
      @transaction = transaction
    end

    def message
      I18n.t("activity.transaction_created",
             type: type,
             amount: money(@transaction.amount),
             description: description_with_category,
             date: @transaction.date,
             id: @transaction.id)
    end
  end
end
