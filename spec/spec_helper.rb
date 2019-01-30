$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'gtin'

RSpec.configure do |c|
  c.example_status_persistence_file_path = 'rspec-results.txt'
end
