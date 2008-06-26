require 'rubygems'
require 'git' # Ruby/Git
require 'git-blog/core_ext'

module GitBlog
  TitleRegexen = {
    'xhtml'     => /^<[^>]+>(.*)<[^>]+>$/,
    'haml'      => /^%[^\s\{]+(?:\{[^\}]\})? (.*)$/,
    'textile'   => /^h\d(?:[^\s\{]|\{[^\}]*\})*\. (.*)$/,
    'markdown'  => /^(.*)$/ # Also works for other
  }
  
  # Returns the path of file relative to the git-blog root.
  # 'Borrowed' mostly wholesale from Haml 2.0.0 d-:
  # def self.Scope path
  #   File.join(File.expand_path( File.dirname(__FILE__) / '..' / '..' ), path.to_s)
  # end
  # Fuck that, using a constant. LAWL.
  Scope = File.expand_path( File.dirname(__FILE__) / '..' / '..' )
end

require 'git-blog/parsers'