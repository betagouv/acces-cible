require "timeout"
require "resolv"

module Dns
  module_function

  RESOLUTION_TIMEOUT = 10.seconds

  def resolvable?(url)
    uri = Link.parse(url)
    host = uri.host
    return false unless host

    Timeout.timeout(RESOLUTION_TIMEOUT) do
      Resolv::DNS.new.getaddress(host)
      true
    end
  rescue Resolv::ResolvError, Timeout::Error, URI::InvalidURIError
    false
  end
end
