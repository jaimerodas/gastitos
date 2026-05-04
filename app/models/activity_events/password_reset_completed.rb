module ActivityEvents
  class PasswordResetCompleted
    def message
      I18n.t("activity.password_reset_completed")
    end
  end
end
