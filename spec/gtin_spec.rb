describe GTIN do
  it "has a version number" do
    expect(GTIN::VERSION).not_to be nil
  end

  describe "#valid_checksum?" do
    it "doesn't crash for invalid id types" do
      expect(GTIN.valid_checksum?('POTATO', '123412341230')).to be(false)
    end

    it "doesn't crash for invalid values" do
      expect(GTIN.valid_checksum?('ISBN', '6')).to be(false)
    end
  end

  describe "#gtin_compatible?" do
    positives = ['GTIN', 'GTIN-14', 'GTIN14', 'ISBN', 'UPC-E', 'UPCE']
    negatives = ['UTF', 'NOTUPC', 'GTIN41']

    positives.each do |id_type|
      it "#{id_type} is GTIN-copmatible" do
        expect(GTIN.gtin_compatible?(id_type)).to eq(true)
      end
    end

    negatives.each do |id_type|
      it "#{id_type} is not GTIN-copmatible" do
        expect(GTIN.gtin_compatible?(id_type)).to eq(false)
      end
    end
  end

  context "direct conversions" do
    direct_test_cases = [
      ['ISSN', '20493630', '09772049363002'],
      ['UPC', '123412341230', '00123412341230'],
      ['UPC-A', '123412341247', '00123412341247'],
      ['EAN', '5012345678900', '05012345678900'],
      ['ISBN', '0306406152', '09780306406157'],
      ['GTIN', '00977204936308', '00977204936308']
    ]

    direct_test_cases.each do |id_type, value, expected_result|
      context id_type do
        subject(:result) do
          GTIN.to_gtin(id_type, value)
        end

        it "converts to GTIN" do
          expect(result).to eq(expected_result)
          expect(result.length).to eq(14)
          expect(result).to include(value[0..-2]) # same contents, different checksum
          expect(GTIN.valid_checksum?('GTIN', result)).to be true
        end
      end
    end
  end

  # Tested via http://www.taltech.com/barcodesoftware/symbologies/upc
  upce_test_cases = [
    ['1234505', '00012000003455'],
    ['1234514', '00012100003454'],
    ['1234523', '00012200003453'],
    ['1234531', '00012300000451'],
    ['1234543', '00012340000053'],
    ['1234558', '00012345000058'],
    ['1234565', '00012345000065'],
    ['1234572', '00012345000072'],
    ['1234589', '00012345000089'],
    ['1234596', '00012345000096']
  ]

  upce_test_cases.each do |input, expected_result|
    context "UPC-E #{input}" do
      subject(:result) do
        GTIN.to_gtin('UPC', input)
      end

      it "converts #{input} to #{expected_result}" do
        expect(result).to eq(expected_result)
      end
    end
  end

  invalid_test_cases = [
    ['ISSN', '9772049363002'],
    ['UPC', '123412341230'],
    ['UPC-A', '123412341247'],
    ['EAN', '5012345678900'],
    ['ISBN', '9780306406157'],
    ['GTIN', '00977204936308']
  ]

  invalid_test_cases.each do |name, value|
    # replace final char with invalid check digit
    invalid_value = value[0..-2] + (9 - value[-1].to_i).to_s
    context "invalid input #{name}: #{invalid_value}" do
      it "correctly detects invalid check digit in #{invalid_value}" do
        expect { GTIN.to_gtin(name, invalid_value) }.to raise_error(GTIN::GtinValidationError)
      end
    end
  end
end
