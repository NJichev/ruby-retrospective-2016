module FetchDeep
  def fetch_deep(keys)
    keys.split('.').reduce(self) do |m, key|
      m[key.to_i] || m[key] || m[key.to_sym]
    end
  end
end

class Hash
  include FetchDeep

  def reshape(shape)
    {}.tap do |h|
      shape.each do |key, val|
        h[key] = pick_reshape_step(val)
      end
    end
  end

  private

  def pick_reshape_step(value)
    if value.is_a?(Hash)
      reshape(value)
    elsif value.is_a?(Array)
      value.map { |v| reshape(v) }
    else
      fetch_deep(value)
    end
  end
end

class Array
  include FetchDeep

  def reshape(shape)
    [].tap do |arr|
      each do |input|
        arr << input.reshape(shape)
      end
    end
  end
end
