class File
  Extensions = %r=^(markdown|textile|haml|sass|css|html|xhtml)$=i
  module Extension
    def method_missing(meth, *args)
      if Extensions =~ meth.to_s
        [self, '.', meth.to_s].join
      else
        super
      end # if
    end # method_missing
  end # Extension
end # File