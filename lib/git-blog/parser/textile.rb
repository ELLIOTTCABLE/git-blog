require 'redcloth'

module GitBlog
  module Parsers
    module Textile
      def self.parse input
        input.gsub!(/^(.*)(\n\s+)*\n/m, '')
        ::RedCloth.new(input).to_html
      end
    end
  end
end