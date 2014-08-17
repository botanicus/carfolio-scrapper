require 'http'
require 'timeout'
require 'digest'

require_relative 'carfolio-scrapper/tor_proxy'
require_relative 'carfolio-scrapper/manufacturer'
require_relative 'carfolio-scrapper/spec'

class UnexpectedHttpStatusError < StandardError
  def initialize(url, response)
    super("Unexpected HTTP status: #{response.status} on #{url}")
  end
end

class NotFoundError < StandardError
  def initialize(url)
    super("Not found: #{url}")
  end
end

$tor = TorProxy.new

USER_AGENT = 'Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)'

def get(url)
  Timeout.timeout(12) do
    response = HTTP.with_headers('User-Agent' => USER_AGENT).get(url)
    if response.status == 404
      raise NotFoundError.new(url)
    elsif response.status != 200
      # Retry with a different IP.
      raise UnexpectedHttpStatusError.new(url, response)
    end
    body = ''
    while chunk = response.body.readpartial
      body += chunk
    end
    STDERR.puts "[LOG] HTTP #{response.status} #{url}"
    return body
  end
rescue Timeout::Error, IOError, SOCKSError::TTLExpired, Net::ReadTimeout, Net::OpenTimeout, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError, UnexpectedHttpStatusError => error
  STDERR.puts "[ERROR] #{error.class} #{error.message}. Requesting new IP & retrying."
  $tor.switch
  retry
end

def open(url)
  digest = Digest::SHA2.hexdigest(url)
  path = File.join('data', "#{digest}.html")
  if File.exist?(path)
    puts "[CACHE] #{url}"
    File.read(path)
  else
    request(url).tap do |body|
      File.open(path, 'w') do |file|
        file.puts(body)
      end
    end
  end
end

def request(url)
  get "http://webcache.googleusercontent.com/search?q=cache:#{url}"
rescue NotFoundError
  get url
end

def time(&block)
  start_time = Time.now
  block.call
  ((Time.now - start_time) / 60).round(2)
end

def log_error(label, error, should_retry)
  action = should_retry ? "Retrying." : "Skipping for now."
  warn "[ERROR] #{error.class}: #{error.message} occured when #{label}. #{action}"
  warn error.backtrace
end
