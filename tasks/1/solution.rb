module Temperature
  module Converter
    def convert_between_temperature_units(units, from, to)
      temperature = convert_to_celsius[from][units]
      convert_from_celsius[to][temperature]
    end

    private

    def convert_to_celsius
      {
        'K' => ->(temp) { (temp - 273.15) },
        'F' => ->(temp) { (temp - 32) / (9.0 / 5) },
        'C' => ->(temp) { temp }
      }
    end

    def convert_from_celsius
      {
        'K' => ->(temp) { temp + 273.15 },
        'F' => ->(temp) { temp * (9.0 / 5) + 32 },
        'C' => ->(temp) { temp }
      }
    end
  end

  module MeltingPoints
    include Converter
    MELTING_POINTS = {
      'water' => 0,
      'ethanol' => -114,
      'gold' => 1_064,
      'silver' => 961.8,
      'copper' => 1_085
    }.freeze

    def melting_point_of_substance(substance, unit, from: 'C')
      temperature = MELTING_POINTS[substance]
      convert_between_temperature_units(temperature, from, unit)
    end
  end

  module BoilingPoints
    include Converter

    BOILING_POINTS = {
      'water' => 100,
      'ethanol' => 78.37,
      'gold' => 2_700,
      'silver' => 2_162,
      'copper' => 2_567 
    }.freeze

    def boiling_point_of_substance(substance, unit, from: 'C')
      temperature = BOILING_POINTS[substance]
      convert_between_temperature_units(temperature, from, unit)
    end
  end
end

include Temperature::Converter
include Temperature::BoilingPoints
include Temperature::MeltingPoints

