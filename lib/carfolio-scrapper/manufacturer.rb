require 'ostruct'
require 'nokogiri'

# Manufacturer has a number of specs.
# I. e. Alma > 1926 Alma Six.
class Manufacturer < OpenStruct
  ROOT_URL = 'http://www.carfolio.com/specifications'

  def self.document
    @document ||= Nokogiri::HTML(open(self::ROOT_URL))
  end

  def self.parse_specs_page
    elements = self.document.css('li.m') +
               self.document.css('li.m1') +
               self.document.css('li.m2') +
               self.document.css('li.m3')
    elements.map do |li|
      Manufacturer.create_from_element(li)
    end.sort_by do |manufacturer|
      "#{manufacturer.name}-#{manufacturer.country}"
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
