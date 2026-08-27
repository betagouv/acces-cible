module CheckHelper
  # FIXME: the `custom_badge_*` methods should not live in the model
  # but in some kind of decorator/presenter/facade pattern thing

  STATUS_TO_BADGE_LEVEL = {
    pending: :info,
    blocked: :info,
    ready: :info,
    running: :new,
    completed: :success,
    errored: :error,
    failed: :error,
    aborted: :error,
  }

  def status_to_badge_text(check)
    if (check.completed? || check.errored?) && check.respond_to?(:custom_badge_text)
      check.custom_badge_text
    else
      check.human_status
    end
  end

  def status_link(check)
    return nil unless check.completed?

    check.custom_badge_link if check.respond_to?(:custom_badge_link)
  end

  def status_to_badge_level(check)
    if check.completed? && check.respond_to?(:custom_badge_status)
      check.custom_badge_status
    else
      STATUS_TO_BADGE_LEVEL[check.current_state.to_sym]
    end
  end

  def check_badge(check, hover: check.tooltip?, no_icon: false)
    badge(
      status: status_to_badge_level(check),
      text: status_to_badge_text(check),
      link: status_link(check),
      hover:,
      no_icon:
    )
  end
end
