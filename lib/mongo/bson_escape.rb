# for storing Selector's or Query's in the db
module BSON
  def self.escape( val )
    return val  unless val.kind_of?(Hash)
    Hash[ val.map  do |key, val|
      k = key.to_s
      k = "_#{k}"  if k[0] == '$'
      [ k.gsub('.', '\*'), self.escape(val) ]
    end ]
  end

  def self.unescape( val )
    return val  unless val.kind_of?(Hash)
    Hash[ val.map  do |key, val|
      k = key.to_s
      k = k[1..-1]  if k[0,2] == '_$'
      [ k.gsub('\*', '.'), self.unescape(val) ]
    end ]
  end
end
