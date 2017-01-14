module FetchDeep
  def fetch_deep(keys)
    keys.split('.').reduce(self) do |m, key|
      begin
        m[key.to_i] || m[key] || m[key.to_sym]
      rescue
        nil
      end
    end
  end
end

class Hash
  include FetchDeep

  def reshape(shape)
    shape.map do |key, val|
      [key, pick_reshape_step(val)]
    end.to_h
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
    map { |input| input.reshape(shape) }
  end
end
