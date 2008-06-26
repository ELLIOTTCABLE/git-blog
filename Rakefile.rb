require 'rubygems'
require 'fileutils'
include FileUtils

$:.unshift File.expand_path('./lib')
require 'git-blog/core'

desc 'Create a new git-blog'
task :create, :destination do |_, params|
  destination = params[:destination].nil? ? './blog' : params[:destination]
  destination = File.expand_path destination
  
  mkdir destination rescue nil
  File.open destination/:Rakefile.rb, File::RDWR|File::TRUNC|File::CREAT do |rakefile|
    rakefile.puts "$:.unshift File.expand_path('#{GitBlog::Scope :lib}')"
    rakefile.puts "require 'git-blog'"
    rakefile.print "\n"; rakefile.close
  end
  puts "** git-blog created at #{destination}!"
  puts "** now `cd #{destination}` and `rake initialize`!"
end