#!/usr/bin/env ruby

# Hosted at https://gist.github.com/botanicus/024075a0046a43c683b6

# 5 hrs
# 11:40 –

if ARGV.empty?
  abort "Usage: #{$0} A B C # Run scrapping for manufacturers starting with A-C."
end

require_relative './lib/carfolio-scrapper'

require 'csv'

# Note about logging: when it goes to STDERR,
# it works fine, everything is written immediately.
# On the other hand, when using STDOUT (with &>> logfile)
# alongside with STDERR, STDERR is written immediately,
# but STDOUT only when the process exists. WTF?
#
# Apparently the same goes for writing to the CSV:
# nothing happens until it's all done or I kill the process.

# Main.
Dir.mkdir('specs') unless Dir.exist?('specs')
Dir.chdir('specs')

manufacturers = Manufacturer.parse_specs_page
groups = manufacturers.group_by do |manufacturer|
  manufacturer.name[0].upcase
end

# Only specified letters (from ARGV).
groups = groups.reduce(Hash.new) do |buffer, (first_char, manufacturers)|
  if ARGV.include?(first_char)
    buffer.merge!(first_char => manufacturers)
  end
  buffer
end

def time(&block)
  start_time = Time.now
  block.call
  ((Time.now - start_time) / 60).round(2)
end

overall_time_in_mins = time do
  groups.each do |first_char, manufacturers|
    STDERR.puts "~ Processing manufacturers starting with '#{first_char}'."
    time_per_letter_in_mins = time do
      CSV.open("#{first_char}.csv", 'w') do |csv|
        csv << Spec::FIELDS
        manufacturers.each do |manufacturer|
          begin
            STDERR.puts "  ~> #{manufacturer.name}"
            attempts = 0
            manufacturer.specs.each do |spec|
              begin
                spec_attempts = 0
                csv << spec.to_row
              rescue => error
                should_retry = spec_attempts < 3; spec_attempts += 1
                STDERR.puts "[ERROR] #{error.class}: #{error.message} occured when processing spec #{spec.name}. #{should_retry ? "Retrying." : "Skipping for now"}."
                retry if should_retry
              end
            end
          rescue => error
            should_retry = attempts < 3; attempts += 1
            STDERR.puts "[ERROR] #{error.class}: #{error.message} occured when processing manufacturer #{manufacturer.name}. #{should_retry ? "Retrying." : "Skipping for now"}."
            retry if should_retry
          end
        end
      end
    end

    STDERR.puts "~ #{first_char}.csv saved. Processing took #{time_per_letter_in_mins}m"
  end
end

STDERR.puts "\n\n ~ All done. Processing took #{overall_time_in_mins}m"
