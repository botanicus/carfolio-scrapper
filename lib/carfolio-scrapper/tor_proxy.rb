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
      'Timeout' => 10,
      'Prompt'  => /250 OK\n/
    }
  end

  def localhost
    Net::Telnet.new(self.telnet_opts)
  end

  def switch
    localhost.cmd(AUTHENTICATE) do |response|
      unless response == OK_250
        raise "Cannot authenticate! Response was: #{response.chomp}"
      end
    end

    localhost.cmd(SIGNAL_NEWNYM) do |response|
      unless response == OK_250
        raise "Cannot switch Tor to a new route! Response was: #{response.chomp}"
      end
    end

    localhost.close
  rescue Errno::ECONNREFUSED => error
    raise "#{error.message}. Is Tor running?"
  end
end
