module GTIN
  extend self

  GTIN_COMPATIBLE_ID_TYPES = %w(UPC GTIN EAN ISSN ISBN).freeze

  GtinValidationError = Class.new(StandardError)

  # raises GtinValidationError if the provided value is a GTIN variant with an invalid checksum.
  # ISSN, ISBN-10, and UPC-E checksums are not validated.
  def to_gtin(id_type, value)
    zero_pad(standardize(id_type, value))
  end

  def standardize(id_type, value)
    case id_type.upcase
    when 'GTIN', 'EAN', 'UPC-A', 'ISBN-13'
      fail_on_invalid_checksum(value)
      value
    when 'UPC', 'UPC-E'
      standardize_upc(value)
    when 'ISSN'
      standardize_issn(value)
    when 'ISBN', 'ISBN-10'
      standardize_isbn(value)
    end
  end

  def standardize_upc(upc)
    case upc.length
    when 12
      fail_on_invalid_checksum(upc)
      upc
    when 7
      # http://www.taltech.com/barcodesoftware/symbologies/upc
      case upc[5]
      when '0', '1', '2'
        with_checksum('0' + upc.slice(0, 2) + upc[5] + '0000' + upc.slice(2, 3))
      when '3'
        with_checksum('0' + upc.slice(0, 3) + '00000' + upc.slice(3, 2))
      when '4'
        with_checksum('0' + upc.slice(0, 4) + '00000' + upc[4])
      else
        with_checksum('0' + upc.slice(0, 5) + '0000' + upc[5])
      end
    else
      raise "Invalid UPC - length is #{upc.length} but should be 7 (UPC-E) or 12 (UPC-A)"
    end
  end

  def standardize_issn(issn)
    case issn.length
    when 13
      fail_on_invalid_checksum(issn)
      issn
    when 8
      with_checksum('977' + issn[0..-2] + '00')
    else
      raise "Invalid ISSN - length is #{issn.length} but should be 8 or 13"
    end
  end

  def standardize_isbn(isbn)
    case isbn.length
    when 13
      fail_on_invalid_checksum(isbn)
      isbn
    when 10
      with_checksum('978' + isbn[0..-2])
    else
      raise "Invalid ISBN - length is #{isbn.length} but should be 10 or 13"
    end
  end

  def zero_pad(gtin)
    gtin.rjust(14, '0')
  end

  # Checksum calculations are only compatible with standardized GTIN variants
  # Excluded: ISSN, ISBN-10, UPC-E, EAN-8

  def with_checksum(unchecked)
    unchecked + compute_checksum(unchecked)
  end

  def compute_checksum(unchecked)
    reversed_digits = unchecked.reverse.chars.map(&:to_i)
    sum = reversed_digits.each_with_index.sum { |digit, idx| digit * (idx.odd? ? 1 : 3) }
    ((10 - sum) % 10).to_s
  end

  def valid_checksum?(identifier)
    compute_checksum(identifier[0..-2]) == identifier[-1]
  end

  def fail_on_invalid_checksum(identifier)
    expected_checksum = compute_checksum(identifier[0..-2])
    actual_checksum = identifier[-1]
    return if actual_checksum == expected_checksum

    raise GtinValidationError.new("Identifier #{identifier} has invalid checksum #{actual_checksum} -- expected #{expected_checksum}")
  end
end
