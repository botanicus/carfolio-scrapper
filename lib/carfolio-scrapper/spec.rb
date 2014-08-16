require 'ostruct'
require 'nokogiri'

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
      STDERR.puts "[WARNING] No timestamps found for #{self.inspect}."
      document.css('table.specs tr').map do |row|
        key = row.at_css('th').text rescue 'timestamps'
        vls = row.css('td').map { |td| td.text.tr("\n ", '  ').strip } - ['']
        STDERR.puts("#{key}: #{vls.inspect}")
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
