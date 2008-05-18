require 'redcloth'

module GitBlog
  module Parsers
    module Markdown
      def self.parse input
        input.gsub!(/^(.*)\n=+(\n\s+)*\n/m, '')
        ::RedCloth.new(input).to_html [:markdown, :textile]
      end
    end
  end
end