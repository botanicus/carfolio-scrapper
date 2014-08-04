#!/usr/bin/env ruby

require 'open-uri'
require 'ostruct'

require 'nokogiri'

# Model can have number of specs.
# I. e. Alma > 1926 Alma Six.
class Model < OpenStruct
  ROOT_URL = 'http://www.carfolio.com/specifications'

  def self.parse_specs_page
    document = Nokogiri::HTML(open(self::ROOT_URL))
    document.css('li.m > a.man').map do |anchor|
      Model.create_from_element(anchor)
    end
  end

  def self.create_from_element(anchor)
    instance = self.new
    relative_url = anchor.attribute('href').value
    instance.url  = [self::ROOT_URL, relative_url].join('/')
    instance.name = anchor.attribute('title').value

    instance
  end

  def specs
    document = Nokogiri::HTML(open(self.url).read)
    document.css('li.detail a.addstable').map do |anchor|
      Spec.create_from_element(anchor)
    end
  end
end

class Spec < OpenStruct
  ROOT_URL = 'http://www.carfolio.com/specifications/models'

  def self.create_from_element(anchor)
    instance = self.new
    relative_url = anchor.attribute('href').value
    instance.url  = [self::ROOT_URL, relative_url].join('/')
    instance.name = anchor.inner_text
    instance.manufacturer = anchor.css('.manufacturer').inner_text
    instance.model = anchor.css('.model').inner_text
    instance.year = anchor.css('.Year').inner_text

    instance
  end

  def fetch
    document = Nokogiri::HTML(open(self.url))
    document.css('table.specs tr').map do |row|
      populate_from_spec_page(row)
    end
  end

  private
  def populate_from_spec_page(row)
    key = row.at_css('th').text rescue 'timestamps'
    values = row.css('td').map { |td| td.text.tr("\n", ' ').strip } - ['']
    self[key] = values unless values.empty?
  end
end

# Main.
models = Model.parse_specs_page
models.each do |model|
  model.specs.each do |spec|
    spec.fetch
    p spec
    exit
  end
end
