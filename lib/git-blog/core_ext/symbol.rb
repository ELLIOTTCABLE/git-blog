class Symbol
  include File::Extension
  
  def /(o)
    File.join(self.to_s, o.to_s)
  end
end