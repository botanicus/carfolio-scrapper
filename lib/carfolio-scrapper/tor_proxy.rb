require 'socksify/http'
require 'tor'
require 'net/telnet'

# Copied from http://martincik.com/?p=402
class TorProxy
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
    @circuit_timeout = 10
  end


  def switch
    localhost = Net::Telnet::new('Host' => @host,
                                 'Port' => @control_port,
                                 'Timeout' => @circuit_timeout,
                                 'Prompt' => /250 OK\n/)
    localhost.cmd('AUTHENTICATE') do |c|
      throw "cannot authenticate to Tor!" if c != "250 OK\n"
    end

    localhost.cmd('SIGNAL NEWNYM') do |c|
      throw "cannot switch Tor to new route!" if c != "250 OK\n"
    end

    localhost.close
  end
end
