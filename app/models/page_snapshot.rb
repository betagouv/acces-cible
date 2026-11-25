class PageSnapshot < ApplicationRecord
  CERTIFICATE_ERRORS = %w[
    net::ERR_CERT_AUTHORITY_INVALID
    net::ERR_CERT_COMMON_NAME_INVALID
    net::ERR_CERT_DATE_INVALID
    net::ERR_SSL_PROTOCOL_ERROR
  ].freeze

  CONNECTION_ERRORS = %w[
    net::ERR_TIMED_OUT
    net::ERR_CONNECTION_REFUSED
  ].freeze

  belongs_to :audit

  enum :kind, { home: "home", accessibility: "accessibility" }

  def failure_reason
    return http_failure_reason if status && status >= 400
    return if html?

    net_error_reason
  end

  private

  def http_failure_reason
    http_status = HTTP::Response::Status.new(status)

    if http_status.unauthorized? || http_status.forbidden?
      :access_denied
    elsif http_status.too_many_requests?
      :probably_blocked
    elsif http_status.not_found? || http_status.gone?
      :not_found
    elsif http_status.server_error?
      :site_error
    else
      :unknown
    end
  end

  def net_error_reason
    case net_error
    when "net::ERR_NAME_NOT_RESOLVED" then :not_found
    when *CERTIFICATE_ERRORS, *CONNECTION_ERRORS, "net::ERR_TOO_MANY_REDIRECTS" then :site_error
    when "net::ERR_CONNECTION_RESET" then :probably_blocked
    when "net::ERR_BLOCKED_BY_CLIENT" then :tool_error
    else :unknown
    end
  end
end
