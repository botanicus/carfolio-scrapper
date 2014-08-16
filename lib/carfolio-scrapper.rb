require 'http'
require 'timeout'

require_relative 'carfolio-scrapper/tor_proxy'
require_relative 'carfolio-scrapper/manufacturer'
require_relative 'carfolio-scrapper/spec'

class UnexpectedHttpStatusError < StandardError
  def initialize(response)
    super("Unexpected HTTP status: #{response.status}")
  end
end

@tor = TorProxy.new

def open(url, *args)
  unless url.match(/webcache.googleusercontent.com/)
    url = "http://webcache.googleusercontent.com/search?q=cache:#{url}"
  end

  Timeout.timeout(24) do
    response = HTTP.with_headers('User-Agent' => USER_AGENT).get(url)
    unless response.status == 200
      # Retry with a different IP.
      raise UnexpectedHttpStatusError.new(response)
    end
    body = ''
    while chunk = response.body.readpartial
      body += chunk
    end
    STDERR.puts "[LOG] HTTP #{response.status} #{url}"
    return body
  end
rescue IOError, Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError, UnexpectedHttpStatusError => error
  STDERR.puts "[ERROR] #{error.class} #{error.message}. Proxy was: #{proxy.first}. Retrying with a different proxy."
  @tor.switch
  retry
end
