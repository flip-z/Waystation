class CampfirePresence
  CACHE_KEY_PREFIX = "campfire:presence".freeze
  EMPTY_KEY_PREFIX = "campfire:empty_since".freeze

  def self.list(room_id)
    Rails.cache.fetch(cache_key(room_id)) { {} }.values
  end

  def self.add(room_id, peer_id, handle)
    data = Rails.cache.fetch(cache_key(room_id)) { {} }
    data[peer_id] = { peer_id: peer_id, handle: handle }
    Rails.cache.write(cache_key(room_id), data)
    Rails.cache.delete(empty_key(room_id))
    data.values
  end

  def self.remove(room_id, peer_id)
    data = Rails.cache.fetch(cache_key(room_id)) { {} }
    data.delete(peer_id)
    Rails.cache.write(cache_key(room_id), data)
    Rails.cache.write(empty_key(room_id), Time.current) if data.empty?
    data.values
  end

  def self.count(room_id)
    Rails.cache.fetch(cache_key(room_id)) { {} }.size
  end

  def self.empty_since(room_id)
    Rails.cache.read(empty_key(room_id))
  end

  def self.clear(room_id)
    Rails.cache.delete(cache_key(room_id))
    Rails.cache.delete(empty_key(room_id))
  end

  def self.cache_key(room_id)
    "#{CACHE_KEY_PREFIX}:#{room_id}"
  end

  def self.empty_key(room_id)
    "#{EMPTY_KEY_PREFIX}:#{room_id}"
  end
end
