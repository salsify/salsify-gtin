module GTIN
  extend self

  Converter = Struct.new(:standardizer, :checksum_computer)

  GtinConverter = Converter.new(:standardize_gtin, :compute_checksum_gtin)
  UpcEConverter = Converter.new(:standardize_upce, :compute_checksum_upce)
  IsbnConverter = Converter.new(:standardize_isbn10, :compute_checksum_isbn10)
  IssnConverter = Converter.new(:standardize_issn8, :compute_checksum_issn8)

  CONVERTER_MAP = {
    [/^(GTIN|EAN)(-?8)?$/i, 8] => GtinConverter,
    [/^(GTIN|EAN)(-?12)?$/i, 12] => GtinConverter,
    [/^(GTIN|EAN|ISBN|ISSN)(-?13)?$/i, 13] => GtinConverter,
    [/^(GTIN|EAN)(-?14)?$/i, 14] => GtinConverter,
    [/^UPC(-?A)?$/i, 12] => GtinConverter,
    [/^UPC(-?E)?$/i, 7] => UpcEConverter,
    [/^ISBN(-?10)?$/i, 10] => IsbnConverter,
    [/^ISSN(-?8)?$/i, 8] => IssnConverter
  }.freeze

  GtinValidationError = Class.new(StandardError)

  # raises GtinValidationError if the provided value has an invalid checksum
  def to_gtin(id_type, value)
    zero_pad(standardize(id_type, value))
  end

  def zero_pad(gtin)
    gtin.rjust(14, '0')
  end

  def standardize(id_type, value, validate_checksum: true)
    fail_on_invalid_checksum(id_type, value) if validate_checksum
    converter = get_converter(id_type, value.length)
    send(converter.standardizer, value)
  end

  def get_converter(id_type, value_length)
    CONVERTER_MAP.each do |(type_matcher, length), converter|
      return converter if type_matcher.match?(id_type) && value_length == length
    end

    raise GtinValidationError.new("No gtin converter found for #{id_type} with length #{value_length}")
  end

  def standardize_gtin(gtin)
    gtin
  end

  def standardize_upce(upce)
    # http://www.taltech.com/barcodesoftware/symbologies/upc
    case upce[5]
    when '0', '1', '2'
      with_checksum('0' + upce.slice(0, 2) + upce[5] + '0000' + upce.slice(2, 3))
    when '3'
      with_checksum('0' + upce.slice(0, 3) + '00000' + upce.slice(3, 2))
    when '4'
      with_checksum('0' + upce.slice(0, 4) + '00000' + upce[4])
    else
      with_checksum('0' + upce.slice(0, 5) + '0000' + upce[5])
    end
  end

  def standardize_issn8(issn)
    with_checksum('977' + issn[0..-2] + '00')
  end

  def standardize_isbn10(isbn)
    with_checksum('978' + isbn[0..-2])
  end

  def with_checksum(unchecked)
    unchecked + compute_checksum_gtin(unchecked)
  end

  def valid_checksum?(id_type, identifier)
    converter = get_converter(id_type, identifier.length)
    expected_checksum = send(converter.checksum_computer, identifier[0..-2])
    identifier[-1] == expected_checksum
  end

  def fail_on_invalid_checksum(id_type, identifier)
    converter = get_converter(id_type, identifier.length)
    expected_checksum = send(converter.checksum_computer, identifier[0..-2])
    actual_checksum = identifier[-1]
    return if actual_checksum == expected_checksum

    raise GtinValidationError.new("#{id_type} #{identifier} has invalid checksum #{actual_checksum} -- expected #{expected_checksum}")
  end

  def compute_checksum_gtin(unchecked)
    reversed_digits = unchecked.reverse.chars.map(&:to_i)
    sum = reversed_digits.each_with_index.sum { |digit, idx| digit * (idx.odd? ? 1 : 3) }
    ((10 - sum) % 10).to_s
  end

  def compute_checksum_isbn10(unchecked_isbn)
    digits = unchecked_isbn.chars.map(&:to_i)
    sum = digits.each_with_index.sum { |digit, idx| digit * (idx + 1) }
    (sum % 11).to_s
  end

  def compute_checksum_issn8(unchecked_issn)
    reversed_digits = unchecked_issn.reverse.chars.map(&:to_i)
    sum = reversed_digits.each_with_index.sum { |digit, idx| digit * (idx + 2) }
    ((11 - sum) % 11).to_s
  end

  # can't be done directly; convert to upc-a first
  def compute_checksum_upce(unchecked_upce)
    standardize('UPC', unchecked_upce + '0', validate_checksum: false)[-1]
  end

  def gtin_compatible?(id_type)
    CONVERTER_MAP.keys.map(&:first).any? { |r| r.match?(id_type) }
  end
end
