module ActivityEvents
  class PasswordResetRequested
    def message
      I18n.t("activity.password_reset_requested")
    end
  end
end
