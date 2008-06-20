# rpeg-markdown
begin
  require 'markdown'
  
# Discount
rescue LoadError
  begin
    require 'rdiscount'
    Markdown = RDiscount
  
  # Maruku
  rescue LoadError
    begin
      require 'maruku'
      Markdown = Maruku
    
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