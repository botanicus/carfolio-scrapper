#!/usr/bin/env ruby

# Hosted at https://gist.github.com/botanicus/024075a0046a43c683b6

# 2 hrs.
# 10:50

require 'open-uri'
require 'http'
require 'ostruct'
require 'csv'
require 'timeout'

require 'nokogiri'

PROXY_LIST = [
  '83.84.168.79:80',
  '81.136.218.30:19829',
  '81.0.240.113:9050',
  '94.70.255.223:1080',
  '46.38.51.49:6011',
  '69.205.138.159:18340',
  '78.47.254.243:5190',
  '24.181.48.53:39676',
  '71.74.78.137:36357',
  '71.165.90.119:50605',
  '94.202.253.67:80',
  '149.255.255.242:80',
  '91.194.247.247:8080',
  '88.247.63.5:8888',
  '195.242.197.131:80',
  '176.197.229.190:3128',
  '23.228.160.2:23372',
  '62.176.28.45:8088',
  '101.55.12.75:1080',
  '212.117.30.254:8080',
  '221.181.104.11:8080',
  '183.221.245.207:80',
  '176.215.1.224:3128',
  '149.255.255.250:80',
  '211.167.76.180:1080',
  '122.96.59.107:82',
  '91.75.144.85:80',
  '109.185.116.199:8080',
  '210.101.131.231:8080',
  '218.108.170.168:82',
  '122.96.59.107:81',
  '119.252.160.34:8080',
  '41.164.142.154:3128',
  '183.224.1.113:80',
  '222.124.198.136:3129',
  '111.13.12.216:80',
  '183.224.1.113:8080',
  '202.101.96.154:8888',
  '119.46.110.17:8080',
  '46.23.70.52:7070',
  '222.132.29.10:8080',
  '65.167.25.254:8080',
  '117.59.217.236:81',
  '118.174.149.118:8080',
  '220.128.77.116:8080',
  '183.224.1.116:80',
  '117.59.217.228:81',
  '119.46.110.17:80',
  '94.228.204.10:8080',
  '177.128.194.114:8080',
  '218.108.170.168:80',
  '122.96.59.107:80',
  '190.103.220.36:8080',
  '111.206.81.248:80',
  '119.235.21.14:3128',
  '101.64.236.206:18000',
  '218.108.170.171:80',
  '223.30.29.200:80',
  '125.39.66.152:80',
  '116.254.102.97:8080',
  '200.10.67.162:8080',
  '27.106.33.161:8080',
  '218.108.170.167:80',
  '177.75.42.33:8080',
  '103.10.151.177:80',
  '223.30.31.158:80',
  '218.108.170.162:80',
  '125.39.66.66:80',
  '85.234.22.126:3128',
  '61.19.51.50:8080',
  '177.36.49.6:8080',
  '77.251.123.14:80',
  '203.114.109.66:3128',
  '213.149.105.12:8080',
  '177.207.81.86:8080',
  '222.124.218.164:8080',
  '122.227.8.190:80',
  '123.124.1.161:808',
  '118.97.44.34:80',
  '122.99.103.218:8080',
  '213.141.141.178:8080',
  '202.195.192.197:3128',
  '195.8.126.22:8888',
  '125.39.68.180:80',
  '182.253.73.188:8080',
  '223.83.100.86:8123',
  '177.37.12.9:8080',
  '116.93.58.84:8080',
  '202.108.50.75:80',
  '119.235.21.13:3128',
  '123.108.14.39:8080',
  '115.238.185.188:80',
  '219.133.31.120:8888',
  '112.124.51.136:808',
  '217.12.201.22:3128',
  '188.241.141.112:8089',
  '210.169.168.88:80',
  '173.198.235.78:8888',
  '199.167.228.36:80',
  '109.104.164.231:8080',
  '62.244.31.16:7808',
  '174.34.166.10:3128',
  '109.175.6.194:8080',
  '81.13.138.141:80',
  '115.114.148.71:80',
  '199.200.120.140:8089',
  '78.40.176.22:8088',
  '107.182.135.43:3127',
  '66.35.68.145:8089',
  '117.211.83.18:3128',
  '218.204.65.128:8123',
  '66.35.68.145:7808',
  '183.221.191.93:8123',
  '210.14.138.102:8080',
  '113.31.27.195:80',
  '41.35.45.224:8080',
  '183.221.55.71:8123',
  '183.221.164.31:8123',
  '183.221.217.32:8123',
  '133.242.53.172:8080',
  '111.161.126.83:8080',
  '113.214.13.1:8000',
  '189.89.170.182:8080',
  '111.161.126.91:8080',
  '111.161.126.88:8080',
  '202.106.16.36:3128',
  '118.97.166.171:8080',
  '49.0.1.86:3128',
  '119.188.46.42:8080',
  '183.207.229.137:80',
  '199.200.120.36:8089',
  '115.182.64.108:8080',
  '189.115.24.114:3128',
  '218.5.74.174:80',
  '118.98.194.99:8080',
  '180.153.32.93:8088',
  '109.175.8.53:8080',
  '222.124.186.228:8080',
  '91.121.167.5:8118',
  '200.84.131.123:8080',
  '186.94.84.98:8080',
  '190.207.198.69:8080',
  '115.236.59.194:3128',
  '190.39.94.53:8080',
  '190.77.216.190:8080',
  '111.161.126.90:8080',
  '190.72.29.28:8080',
  '190.36.18.17:8080',
  '121.14.228.16:29832',
  '183.141.74.161:80',
  '118.97.70.138:8080',
  '183.89.105.5:3128',
  '190.184.144.78:8080',
  '211.151.13.22:81',
  '113.57.252.104:80',
  '222.87.129.30:80',
  '186.212.98.209:8080',
  '190.207.10.177:8080',
  '113.53.250.62:8080',
  '190.203.72.158:8080',
  '61.135.153.22:80',
  '190.78.190.109:8080',
  '85.185.42.3:8080',
  '190.198.83.144:8080',
  '187.78.65.169:8080',
  '27.111.34.134:3128',
  '183.221.60.150:8123',
  '183.221.160.22:8123',
  '190.207.156.79:8080',
  '94.198.135.79:80',
  '190.204.0.140:8080',
  '117.170.220.201:8123',
  '200.216.227.180:8080',
  '125.227.240.212:8080',
  '183.221.50.10:8123',
  '84.33.2.24:80',
  '221.182.101.248:8123',
  '190.203.204.221:8080',
  '186.95.58.220:8080',
  '201.248.115.170:8080',
  '183.238.17.126:3128',
  '111.161.126.93:8080',
  '183.221.185.86:8123',
  '121.179.211.221:3128',
  '116.197.134.70:8080',
  '101.4.60.47:80',
  '211.151.129.142:8080',
  '106.3.40.249:8081',
  '202.159.6.146:555',
  '183.221.220.50:8123',
  '221.182.101.152:8123',
  '123.127.6.131:8118',
  '222.85.1.123:8118',
  '27.111.35.85:8080',
  '114.112.91.116:90',
  '115.239.248.235:8080',
  '142.0.42.8:80',
  '119.188.2.54:8081',
  '113.57.230.83:80',
  '201.221.131.203:8080',
  '149.5.32.249:8080',
  '186.67.46.230:8080',
  '202.162.223.34:3128',
  '211.77.5.38:3128',
  '222.88.242.213:9999',
  '222.87.129.29:80',
  '223.30.29.207:80',
  '117.170.55.55:8123',
  '123.234.49.194:8080',
  '85.185.42.2:8080',
  '223.83.63.106:8123',
  '190.201.99.170:8080',
  '190.211.129.92:8080',
  '177.99.176.146:8080',
  '113.57.252.1.89:8080',
  '183.221.50.68:8123',
  '186.88.106.159:8080',
  '182.253.48.252:3128',
  '118.97.144.102:8080',
  '119.4.115.51:8090',
  '190.36.24.182:8080',
  '218.71.136.39:8888',
  '210.70.0.50:3128',
  '202.185.27.34:3128',
  '49.0.2.182:8080',
  '117.170.232.28:8123',
  '190.203.202.33:8080',
  '200.42.69.91:8080',
  '183.57.78.93:80',
  '201.221.133.86:8080',
  '200.41.168.3:3128',
  '222.218.152.36:9999',
  '80.191.247.178:8080',
  '186.94.69.133:8080',
  '80.90.116.124:8080',
  '121.12.255.212:8085',
  '66.135.33.230:3128',
  '117.171.225.169:8123',
  '190.73.105.204:8080',
  '186.94.21.199:8080',
  '103.11.216.165:8080',
  '139.0.2.162:8080',
  '117.170.23.141:8123',
  '190.201.5.170:8080',
  '202.118.236.130:3128',
  '112.199.65.210:8080',
  '60.18.147.109:8085',
  '180.153.32.9:8080',
  '186.95.60.92:8080',
  '101.255.66.10:80',
  '101.255.28.38:8080',
  '202.98.123.126:8080',
  '200.110.32.56:8080',
  '111.13.13.135:80',
  '212.13.49.186:8085'
]

USER_AGENT = 'Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)'

def get_random_proxy
  ip, port = PROXY_LIST[rand(PROXY_LIST.length)].split(':')
  [ip, port.to_i]
end

alias __open__ open

class UnexpectedHttpStatusError < StandardError
  def initialize(response)
    super("Unexpected HTTP status: #{response.status}")
  end
end

def open(url, *args)
  unless url.match(/webcache.googleusercontent.com/)
    url = "http://webcache.googleusercontent.com/search?q=cache:#{url}"
  end

  proxy = get_random_proxy
  Timeout.timeout(24) do
    response = HTTP.with_headers('User-Agent' => USER_AGENT).
         via(*proxy).get(url)
    unless response.status == 200
      # Try with a different proxy.
      raise UnexpectedHttpStatusError.new(response)
    end
    body = ''
    while chunk = response.body.readpartial
      body += chunk
    end
    return body
  end
rescue IOError, Timeout::Error, Errno::ECONNREFUSED, UnexpectedHttpStatusError => error
  warn "[ERROR] #{error.class} #{error.message}. Proxy was: #{proxy.first}. Retrying with a different proxy."
  retry
end

# Manufacturer can have number of specs.
# I. e. Alma > 1926 Alma Six.
class Manufacturer < OpenStruct
  ROOT_URL = 'http://www.carfolio.com/specifications'

  def self.document
    @document ||= Nokogiri::HTML(open(self::ROOT_URL))
  # rescue
  #   warn "~ Retrying: get the spec page."
  #   retry
  end

  def self.parse_specs_page
    elements = self.document.css('li.m') +
               self.document.css('li.m1') +
               self.document.css('li.m2') +
               self.document.css('li.m3')
    elements.map do |li|
      Manufacturer.create_from_element(li)
    end
  end

  def self.create_from_element(li)
    anchor = li.at_css('a.man')
    instance = self.new
    instance.country = li.at_css('span').text
    relative_url = anchor.attribute('href').value
    instance.url  = [self::ROOT_URL, relative_url].join('/')
    instance.name = anchor.text.strip

    instance
  end

  def specs
    document = Nokogiri::HTML(open(self.url))
    document.css('li.detail a.addstable').map do |anchor|
      Spec.create_from_element(anchor, self)
    end
  end
end

class Spec < OpenStruct
  ROOT_URL = 'http://www.carfolio.com/specifications/models'

  FIELDS   = [
    # From manufacturer.
    'Manufacturer',
    'Country',

    # Spec-specific.
    'Vehicle',
    'Body Type',
    'Number of Doors',
    'Engine Type',
    'Engine Manufacturer',
    'Engine Code', # usually missing
    'Cylinders',
    'Capacity',
    'Fuel System', # usually missing
    'Drive Wheels',
    'Tyres Front', # usually missing
    'Tyres Rear',  # usually missing
    'Gearbox',
    'Carfolio.com ID',
    'Date record was added',
    'Date record was modified'
  ]

  def self.create_from_element(anchor, manufacturer)
    instance = self.new

    instance['Manufacturer'] = manufacturer.name
    instance['Country'] = manufacturer.country

    relative_url = anchor.attribute('href').value
    instance.url  = [self::ROOT_URL, relative_url].join('/')
    # There's invalid unicode in http://www.carfolio.com/specifications/models/car/?car=306449
    instance['Vehicle'] = anchor.text.encode('utf-8', invalid: :replace).strip
    #force_encoding('iso-8859-2').encode('utf-8', invalid: :replace).strip
    #instance['Year'] = anchor.css('.Year').inner_text

    instance.fetch
    instance
  end

  def fetch
    document = Nokogiri::HTML(open(self.url))
    document.css('table.specs tr').map do |row|
      populate_from_spec_page(row)
    end

    begin
      timestamps = self.timestamps.scan(/\d{4}-\d{2}-\d{2}/)
      self['Date record was added'] = timestamps[0]
      self['Date record was modified'] = timestamps[1]
    rescue
      warn "[WARNING] No timestamps found for #{self.inspect}."
      document.css('table.specs tr').map do |row|
        key = row.at_css('th').text rescue 'timestamps'
        vls = row.css('td').map { |td| td.text.tr("\n ", '  ').strip } - ['']
        warn("#{key}: #{vls.inspect}")
      end
    end
  end

  def to_row
    self.class::FIELDS.map do |attribute|
      self[attribute]
    end
  end

  private
  def populate_from_spec_page(row)
    key = row.at_css('th').text rescue 'timestamps'
    if corrected_key_name = self.class::FIELDS.find { |attribute| key.downcase == attribute.downcase }
      key = corrected_key_name
    end

    # The second replaced value in String#tr here is non-breaking space.
    # It can be produced by Alt-Space on OS X.
    values = row.css('td').map { |td| td.text.tr("\n ", '  ').strip } - ['']
    if values.length == 1
      self[key] = values[0]
    elsif values.length > 1
      self[key] = values
    end
  end
end

# Main.
Dir.mkdir('specs') unless Dir.exist?('specs')
Dir.chdir('specs')

manufacturers = Manufacturer.parse_specs_page
groups = manufacturers.group_by do |manufacturer|
  manufacturer.name[0].upcase
end

# Start from 'S'.
groups = groups.reduce(Hash.new) do |buffer, (first_char, manufacturers)|
  if ARGV.include?(first_char)
    buffer.merge!(first_char => manufacturers)
  end
  buffer
end

# Ford only.
# groups = groups.reduce(Hash.new) do |buffer, (first_char, manufacturers)|
#   if manufacturers.any? { |manufacturer| manufacturer.name == 'Ford' }
#     buffer.merge!(first_char => manufacturers.select { |manufacturer|
#       manufacturer.name == 'Ford'
#     })
#   end

#   buffer
# end

processing_start_time = Time.now
groups.each do |first_char, manufacturers|
  puts "~ Processing manufacturers starting with '#{first_char}'."
  start_time = Time.now
  CSV.open("#{first_char}.csv", 'w') do |csv|
    csv << Spec::FIELDS
    manufacturers.each do |manufacturer|
      begin
        puts "  ~> #{manufacturer.name}"
        attempts = 0
        manufacturer.specs.each do |spec|
          begin
            spec_attempts = 0
            csv << spec.to_row
          rescue => error
            should_retry = spec_attempts < 3; spec_attempts += 1
            warn "[ERROR] #{error.class}: #{error.message} occured when processing spec #{spec.name}. #{should_retry ? "Retrying." : "Skipping for now"}."
            retry if should_retry
          end
        end
      rescue => error
        should_retry = attempts < 3; attempts += 1
        warn "[ERROR] #{error.class}: #{error.message} occured when processing manufacturer #{manufacturer.name}. #{should_retry ? "Retrying." : "Skipping for now"}."
        retry if should_retry
      end
    end
  end
  puts "~ #{first_char}.csv saved. Processing took #{((Time.now - start_time) / 60).round(2)}m"
  # Do only 'S'.
  # exit
end
puts "\n\n ~ All done. Processing took #{((Time.now - processing_start_time) / 60).round(2)}m"
