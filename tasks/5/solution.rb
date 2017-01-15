class DataModel
  class DeleteUnsavedRecordError < StandardError
  end

  class UnknownAttributeError < StandardError
  end

  attr_accessor :id

  def initialize(attributes = {})
    attributes.each do |attribute, value|
      setter = "#{attribute}="
      send(setter, value) if respond_to? setter
    end
  end

  def store
    self.class.data_store
  end

  def save
    if @id
      store.update(id, to_h)
    else
      @id = store.next_id
      store.create(to_h)
    end
    self
  end

  def ==(other)
    return false unless other.instance_of? self.class
    return true if id && id == other.id
    object_id == other.object_id
  end

  def delete
    if @id
      store.delete(to_h)
      self
    else
      raise DeleteUnsavedRecordError
    end
  end

  def attributes
    self.class.attributes
  end

  def to_h
    {}.tap do |hash|
      hash[:id] = id
      attributes.each do |getter|
        hash[getter.to_sym] = send(getter)
      end
    end
  end
end
class << DataModel
  def where(query)
    query.keys.each do |attribute|
      unless attributes.include? attribute
        raise DataModel::UnknownAttributeError, "Unknown attribute #{attribute}"
      end
    end
    data_store.find(query).map do |params|
      instance_eval do
        new(params)
      end
    end
  end

  def attributes(*attributes)
    return @attributes if @attributes
    @attributes = attributes + [:id]
    attr_accessor(*attributes)
    attributes.each do |attribute|
      define_singleton_method "find_by_#{attribute}" do |value|
        where({ attribute.to_sym => value })
      end
    end
  end

  def data_store(store = Store.new)
    @store ||= store
  end
end

class Store
  attr_reader :store

  def initialize
    @id = 0
  end

  def next_id
    @id += 1
  end
end
class HashStore < Store
  def initialize
    @store = {}
    super
  end

  def create(record)
    store[record[:id]] = record
  end

  def find(query)
    [].tap do |result|
      get(query) do |_id, record|
        result << record
      end
    end
  end

  def update(id, new_attributes)
    store[id].merge!(new_attributes)
  end

  def delete(query)
    get(query) { |id, _record| store.delete(id) }
  end

  private

  def get(query)
    store.each do |id, record|
      yield [id, record] if record.merge(query) == record
    end
  end
end
class ArrayStore < Store
  def initialize
    @store = []
    super
  end

  def create(record)
    store << record
  end

  def find(query)
    [].tap do |result|
      get(query) do |record|
        result << record
      end
    end
  end

  def update(id, new_attributes)
    get(id: id) do |record|
      record.merge!(new_attributes)
    end
  end

  def delete(query)
    get(query) { |record| @store -= [record] }
  end

  private

  def get(query)
    store.each do |record|
      yield record if record.merge(query) == record
    end
  end
end
