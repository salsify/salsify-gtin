# GTIN

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'salsify-gtin'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install salsify-gtin

And load it with:

    $ require 'gtin'

## Usage

This gem is all about validating GTIN-compatible identifiers and converting
them to a standardized GTIN-14 representation. Supported input types include
GTIN, EAN-13, UPC-A, UPC-E, ISBN-10, ISBN-13, and ISSN. Inputs must be strings
containing only digits and include the check digit (see examples below).

### Examples:

```
# UPC-A
GTIN.to_gtin('UPC', '123412341230') => '00123412341230'
GTIN.compute_checksum_gtin('12341234123') =>'0' # UPC-A is a subset of GTIN
GTIN.compute_checksum_gtin('0012341234123') =>'0'

# UPC-E
GTIN.to_gtin('UPC', '1236432') => '00012300000642'

# ISBN-10
GTIN.to_gtin('ISBN', '0306406152') => '09780306406157'
GTIN.compute_checksum_isbn10('030640615') =>'2'
GTIN.compute_checksum_gtin('0978030640615') =>'7' # ISBN-13 is a subset of GTIN

# ISBN-13 with an incorrect check digit
GTIN.to_gtin('ISBN', '9780306406150') => GtinValidationError (invalid checksum)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake spec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org)
.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/salsify/gtin.## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

