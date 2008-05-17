require 'haml'

module GitBlog
  module Parsers
    module Haml
      def self.parse input
        input.gsub!(/^(.*)(\n\s+)*\n/m, '')
        ::Haml::Engine.new(input).render
      end
    end
  end
end