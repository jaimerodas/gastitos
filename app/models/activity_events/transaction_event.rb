module ActivityEvents
  class TransactionEvent
    include TransactionFormatting

    def initialize(transaction, i18n_key)
      @transaction = transaction
      @i18n_key = i18n_key
    end

    def message
      I18n.t(@i18n_key,
             type: type,
             amount: money(@transaction.amount),
             description: description_with_category,
             date: @transaction.date,
             id: @transaction.id)
    end
  end
end
