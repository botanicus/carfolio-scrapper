#!/usr/bin/env ruby

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
    document.css('li.m').map do |li|
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
    'Year',
    'Vehicle',
    #=["side valve (SV)  2 valves per cylinder 8 valves in total"]
    #Wheelbase=["3010", "118.5"]
    #Bore × Stroke=["80 × 180 mm 3.15 × 7.09 in"]
    #Bore/stroke ratio=["0.44"]
    #maximum power output=["61 PS (60 bhp) (45 kW)"]
    #Specific output=["16.6 bhp/litre0.27 bhp/cu in"]
    #Unitary capacity=["905 cc"]
    #Aspiration=["Normal"]
    #Compressor=["N/A"]
    #Intercooler=["None"]
    #Catalytic converter=["N"]
    #Maximum speed=["121 km/h (75 mph)"]
    #Drive wheels=["rear wheel drive  "]
    #Torque split=["N/A"]
    #Brakes F/R=["-/Dr"]
    #Gearbox=["3 speed manual"]
    #RAC rating=["15.9"]
    #Insurance classification=["No information available"]
    #Tax band=["No information available"]
    # Continue here!
    #Engine position=["front"]
    #Engine coolant=["Water"]
    #Engine layout=["longitudinal"]
    'Body Type', #Body type
    'Number of Doors', #Number of doors
    'Engine Type', #engine type
    'Engine Manufacturer', #Engine manufacturer
    'Engine Code', #Engine code (usually missing)
    'Cylinders', #
    'Capacity', #
    'Fuel System',
    'Chassis',
    'Drive Wheels',
    'Tyres Front',
    'Tyres Rear',
    'Gearbox',
    'Carfolio.com ID', #
    'Date record was added', #
    'Date record was modified' #
  ]

  def self.create_from_element(anchor, manufacturer)
    instance = self.new

    instance['Manufacturer'] = manufacturer.name
    instance['Country'] = manufacturer.country

    relative_url = anchor.attribute('href').value
    instance.url  = [self::ROOT_URL, relative_url].join('/')
    instance['Vehicle'] = anchor.inner_text
    instance['Year'] = anchor.css('.Year').inner_text

    instance.fetch
    instance
  end

  def fetch
    document = Nokogiri::HTML(open(self.url))
    document.css('table.specs tr').map do |row|
      populate_from_spec_page(row)
    end

    timestamps = self.timestamps.scan(/\d{4}-\d{2}-\d{2}/)
    self['Date record was added'] = timestamps[0]
    self['Date record was modified'] = timestamps[1]
  end

  def to_csv
    self.class::FIELDS.map do |attribute|
      self[attribute]
    end
  end

  private
  def populate_from_spec_page(row)
    key = row.at_css('th').text rescue 'timestamps'
    values = row.css('td').map { |td| td.text.tr("\n", ' ').strip } - ['']
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
  manufacturer.name[0].downcase
end

groups.each do |first_char, manufacturers|
  puts "~ Processing manufacturers starting with '#{first_char}'."
  CSV.open("#{first_char.upcase}.csv", 'w') do |csv|
    csv << Spec::FIELDS
    manufacturers.each do |manufacturer|
      puts "  ~> #{manufacturer.name}"
      manufacturer.specs.each do |spec|
        p spec
        csv << spec.to_csv
      end
    end
  end
end
