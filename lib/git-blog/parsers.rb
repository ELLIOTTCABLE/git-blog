module GitBlog
  module Parsers
    def self.fix_pres string
      string.gsub %r!([ \t]*)<pre>(.*?)</pre>!m do |match|
        match.gsub(/^#{$1}/, '')
      end
    end
  end
end