require 'socksify/http'
require 'tor'
require 'net/telnet'

# Copied from http://martincik.com/?p=402
class TorProxy
  AUTHENTICATE  = 'AUTHENTICATE'
  SIGNAL_NEWNYM = 'SIGNAL NEWNYM'
  OK_250 = "250 OK\n"

  attr_reader :proxy, :host, :port

  def initialize(host = 'localhost', port = 9050, control_port = 9051)
    unless Tor.available?
      raise <<-EOS
        Tor isn't installed. Install Tor to use this module.
        See http://torproject.org or `brew install tor`.
      EOS
    end

    TCPSocket.socks_server = host
    TCPSocket.socks_port = port

    @proxy = Net::HTTP.SOCKSProxy(host, port)
    @host = host
    @port = port
    @control_port = control_port
  end

  def telnet_opts
    @telnet_opts ||= {
      'Host'    => @host,
      'Port'    => @control_port,
      'Timeout' => false,
      'Prompt'  => /250 OK\n/
    }
  end

  def localhost
    @localhost ||= begin
      localhost = Net::Telnet.new(self.telnet_opts)

      localhost.cmd(AUTHENTICATE) do |response|
        unless response == OK_250
          raise "Cannot authenticate! Response was: #{response.chomp}"
        end
      end

      localhost
    end
  end

  WAIT_SECONDS = 2.5

  def switch
    # Make sure we're not too fast, otherwise
    # Tor will hold us even longer. Check the logs.
    #
    # This is the bottleneck of the app.
    waited_already = Time.now - @last_switch
    if @last_switch && waited_already < WAIT_SECONDS
      will_wait = WAIT_SECONDS - waited_already
      warn "[WARN] Waiting before switching IP for #{will_wait}s."
      sleep will_wait
    end

    localhost.cmd(SIGNAL_NEWNYM) do |response|
      unless response == OK_250
        raise "Cannot switch Tor to a new route! Response was: #{response.chomp}"
      end
    end

    @last_switch = Time.now
  rescue Errno::ECONNREFUSED => error
    raise "#{error.message}. Is Tor running?"
  rescue Errno::ECONNRESET, Errno::EPIPE
    @localhost = nil
    retry
  end
end
