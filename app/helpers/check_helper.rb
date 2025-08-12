module CheckHelper
  # FIXME: the `custom_badge_*` methods should not live in the model
  # but in some kind of decorator/presenter/facade pattern thing
  def status_to_badge_text(check)
    if check.passed? && check.respond_to?(:custom_badge_text)
      check.custom_badge_text
    else
      check.human_status
    end
  end

  def status_link(check)
    return nil if not check.passed?

    check.custom_badge_link if check.respond_to?(:custom_badge_link)
  end

  def status_to_badge_level(check)
    if check.failed?
      :error
    elsif check.pending? || check.blocked?
      :info
    elsif check.passed? && check.respond_to?(:custom_badge_status)
      check.custom_badge_status
    else
      :success
    end
  end

  def to_badge(check)
    [
      status_to_badge_level(check),
      status_to_badge_text(check),
      status_link(check)
    ].compact
  end
end
