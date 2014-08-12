#!/usr/bin/env ruby

# Hosted at https://gist.github.com/botanicus/024075a0046a43c683b6

require 'open-uri'
require 'ostruct'
require 'csv'

require 'nokogiri'

# Manufacturer can have number of specs.
# I. e. Alma > 1926 Alma Six.
class Manufacturer < OpenStruct
  ROOT_URL = 'http://www.carfolio.com/specifications'

  def self.parse_specs_page
    document = Nokogiri::HTML(open(self::ROOT_URL))
    elements = document.css('li.m') +
               document.css('li.m1') +
               document.css('li.m2') +
               document.css('li.m3')
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
    document = Nokogiri::HTML(open(self.url).read)
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
# groups = groups.reduce(Hash.new) do |buffer, (first_char, manufacturers)|
#   buffer.merge!(first_char => manufacturers) if first_char >= 'S'
#   buffer
# end

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
