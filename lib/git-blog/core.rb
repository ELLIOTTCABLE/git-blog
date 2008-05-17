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
  
  Location = File.expand_path( File.dirname(__FILE__) / '..' / '..')
end

require 'git-blog/parsers'