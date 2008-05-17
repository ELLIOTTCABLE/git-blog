module GitBlog
  module Parsers
    module HTML
      def self.parse input
        input.gsub!(/^(.*)(\n\s+)*\n/m, '')
        input
      end
    end
  end
end