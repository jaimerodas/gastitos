class ActivityLogger
  mattr_accessor :log_dir, default: Rails.root.join("storage", "activity_logs")

  MAX_SIZE = 1.megabyte
  MAX_FILES = 5

  class << self
    def log(user, message)
      path = log_path(user)
      FileUtils.mkdir_p(path.dirname)
      rotate(path) if path.exist? && path.size >= MAX_SIZE
      timestamp = Time.current.strftime("%Y-%m-%d %H:%M:%S")
      File.open(path, "a") { |f| f.puts "[#{timestamp}] #{message}" }
    end

    def recent_lines(user, count = 50)
      path = log_path(user)
      return [] unless path.exist?

      lines = File.readlines(path, chomp: true)
      lines.last(count).reverse
    end

    def log_path(user)
      log_dir.join("user_#{user.id}.log")
    end

    def log_transaction_created(user, transaction)
      type = transaction_type(transaction)
      description = transaction.description.present? ? "#{transaction.category.name}: #{transaction.description}" : transaction.category.name
      log(user, "Creó #{type}: #{format_amount(transaction)} en #{description} el #{transaction.date} (ID: #{transaction.id})")
    end

    def log_transaction_updated(user, transaction, changes)
      type = transaction_type(transaction)
      details = format_changes(transaction, changes)
      log(user, "Editó #{type} ##{transaction.id}: #{details}")
    end

    def log_transaction_destroyed(user, transaction)
      type = transaction_type(transaction)
      description = transaction.description.present? ? "#{transaction.category.name}: #{transaction.description}" : transaction.category.name
      log(user, "Eliminó #{type}: #{format_amount(transaction)} en #{description} del #{transaction.date} (ID: #{transaction.id})")
    end

    def log_login(user)
      log(user, "Inició sesión")
    end

    def log_logout(user)
      log(user, "Cerró sesión")
    end

    def log_password_reset_requested(user)
      log(user, "Solicitó restablecimiento de contraseña")
    end

    def log_password_reset_completed(user)
      log(user, "Restableció su contraseña")
    end

    private

    def transaction_type(transaction)
      transaction.category.expense? ? "gasto" : "ingreso"
    end

    def format_amount(transaction)
      "$#{'%.2f' % transaction.amount.abs}"
    end

    def rotate(path)
      (MAX_FILES - 1).downto(1) do |i|
        old_path = Pathname.new("#{path}.#{i}")
        new_path = Pathname.new("#{path}.#{i + 1}")
        FileUtils.mv(old_path, new_path) if old_path.exist?
      end
      FileUtils.mv(path, Pathname.new("#{path}.1"))
    end

    def format_changes(transaction, changes)
      parts = []

      if changes.key?("amount")
        old_amount, new_amount = changes["amount"]
        parts << "monto $#{'%.2f' % old_amount.abs}→$#{'%.2f' % new_amount.abs}"
      end

      if changes.key?("category_id")
        old_cat = Category.find_by(id: changes["category_id"].first)&.name || "?"
        new_cat = transaction.category.name
        parts << "categoría #{old_cat}→#{new_cat}"
      end

      if changes.key?("date")
        old_date, new_date = changes["date"]
        parts << "fecha #{old_date}→#{new_date}"
      end

      if changes.key?("description")
        old_desc, new_desc = changes["description"]
        parts << "descripción \"#{old_desc}\"→\"#{new_desc}\""
      end

      parts.join(", ")
    end
  end
end
