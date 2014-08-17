#!/usr/bin/env ruby

# Usage:
# ./scrapper.rb A     # Run for manufacturers starting with A.
# ./scrapper.rb A B C # Run for manufacturers starting with A-C.
# ./scrapper.rb       # Run for all manufacturers.

puts "PID #{Process.pid}\n\n"

ARGV.push(*('A'..'Z').to_a) if ARGV.empty?

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
#
# That's why we need this:

$stdout.sync = true

# Main.
Dir.mkdir('specs') unless Dir.exist?('specs')
Dir.mkdir('data')  unless Dir.exist?('data')

# Group manufacturers by the first letter.
manufacturers = Manufacturer.parse_specs_page
groups = manufacturers.group_by do |manufacturer|
  manufacturer.name[0].upcase
end

# Filter only specified letters (from ARGV).
groups = groups.reduce(Hash.new) do |buffer, (first_char, manufacturers)|
  if ARGV.include?(first_char)
    buffer.merge!(first_char => manufacturers)
  end
  buffer
end

overall_time_in_mins = time do
  ARGV.sort.each do |first_char|
    puts "~ Processing manufacturers starting with '#{first_char}'."

    time_per_letter_in_mins = time do
      CSV.open("specs/#{first_char}.csv", 'w') do |csv|
        csv.sync = true # No buffering.
        csv << Spec::FIELDS
        while manufacturer = groups[first_char].shift
          File.open("dump-#{Time.now.to_i}", 'w') { |file| ObjectSpace.each_object { |object| file.puts(object.inspect) } }
          begin
            puts "  ~> #{manufacturer.name}"
            attempts = 0
            specs = manufacturer.specs
            while spec = specs.shift
              begin
                spec_attempts = 0
                csv << spec.to_row
              rescue => error
                should_retry = spec_attempts < 3; spec_attempts += 1
                log_error("processing spec #{spec.name}", error, should_retry)
                retry if should_retry
              end
            end
          rescue => error
            should_retry = attempts < 3; attempts += 1
            log_error("processing manufacturer #{manufacturer.name}", error, should_retry)
            retry if should_retry
          end
        end
      end
    end

    puts "~ #{first_char}.csv saved. Processing took #{time_per_letter_in_mins}m"
  end
end

puts "\n\n ~ All done. Processing took #{overall_time_in_mins}m"
