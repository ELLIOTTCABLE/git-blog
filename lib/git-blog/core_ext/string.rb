class String
  include File::Extension
  
  def slugize
    string = self
    string = string.downcase
    string = string.strip
    string = string.gsub /[^a-z0-9_]/, '_'
    string = string.gsub /_+/, '_'
  end
  
  def /(o)
    File.join(self, o.to_s)
  end
end