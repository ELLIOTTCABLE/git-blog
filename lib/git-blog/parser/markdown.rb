# Maruku
begin
  require 'maruku'
  Markdown = Maruku
  
# rpeg-markdown
rescue LoadError
  begin
    require 'markdown'
  
  # Discount
  rescue LoadError
    begin
      require 'rdiscount'
      Markdown = RDiscount
    
    # BlueCloth
    rescue LoadError
      require 'bluecloth'
      Markdown = BlueCloth
    end
  end
end

module GitBlog
  module Parsers
    module Markdown
      def self.parse input
        input.gsub!(/^(.*)\n=+(\n\s+)*\n/m, '')
        ::Markdown.new(input).to_html
      end
    end
  end
end