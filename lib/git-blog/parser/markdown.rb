require 'maruku'

module GitBlog
  module Parsers
    module Markdown
      def self.parse input
        input.gsub!(/^(.*)\n=+(\n\s+)*\n/m, '')
        ::Maruku.new(input).to_html
      end
    end
  end
end