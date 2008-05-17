require 'fileutils'
include FileUtils

require 'git-blog/core'

desc 'Setup the blog repository'
task :initialize do
  path = File.expand_path '.'
  
  # Will create the repo if it doesn't exist
  until (blog = Git.open path rescue false)
    Git.init path
  end
  
  cd path
  mkdir 'posts'
  mkdir 'design'
  %w(welcome_to_your_git_blog.markdown .gitignore).each do |file|
    cp File.join(GitBlog::Location, 'defaults', file), 'posts'
  end
  %w(main.css post.haml index.haml).each do |file|
    cp File.join(GitBlog::Location, 'defaults', file), 'design'
  end
  
  blog.add
  blog.commit_all("A bird... no, a plane... no, a git-blog!")
end

desc 'Attach the blog to a GitHub repository'
task :github, :user_name, :repo_name do |_, params|
  path = File.expand_path '.'
  user_name = params[:user_name].nil? ? %x(whoami).chomp : params[:user_name]
  repo_name = params[:repo_name].nil? ? File.basename(path) : params[:repo_name]
  
  raise "** You haven't used `rake initialize` yet." unless
    File.directory? File.join(path, 'posts') and
    (blog = Git.open path rescue false)
  
  github = blog.add_remote 'github', "git@github.com:#{user_name.downcase}/#{repo_name.downcase}.git"
  blog.push github
end

desc 'Create and open for editing a new post'
task :post do
  @resume = false
  temporary_post = :post_in_progress.markdown
  
  if File.file? temporary_post
    puts '** You have an unfinished post from before,'
    puts 'do you want to r)esume it or overwrite it with a n)ew one? '
    case STDIN.gets
    when /r/i
      @resume = true
    when /n/i
      # do nothing, go on to overwriting it
    else
      raise 'Invalid entry, exiting out'
    end
  end
  
  unless @resume
    File.open temporary_post, File::RDWR|File::TRUNC|File::CREAT do |post|
      post.puts  'Replace this text with your title!'
      post.puts  '=================================='
      post.print "\n"
      post.close
    end
  end
  
  system "#{ENV['VISUAL']} #{temporary_post}"
  
  first_line = File.open(temporary_post, File::RDWR|File::CREAT).gets.chomp
  markup = case first_line
    when /^\</        then 'xhtml'
    when /^\%/        then 'haml'
    when /^\#|h\d\./  then 'textile'
    else                   'markdown'
  end

  title = (first_line.match GitBlog::TitleRegexen[markup])[1]
  path = :posts / title.slugize.send(markup.to_sym)
  mv temporary_post, path
  
  blog = Git.open File.expand_path('.')
  blog.add path
  blog.commit "New post: #{title}"
  
  puts "Post '#{title.slugize}' comitted."
end

desc 'Push changes'
task :push, :remote_name do |_, params|
  remote_name = params[:remote_name].nil? ? 'github' : params[:remote_name]
  blog = Git.open '.'
  remote = blog.remote remote_name
  blog.push remote
  puts "Changes pushed to #{remote_name}."
end

desc 'Remove all generated xhtml'
task :clobber do
  Dir['posts/*.xhtml'].each do |path|
    rm_f path
  end
end

desc 'Generate xhtml files from posts and design'
task :deploy => :clobber do
  Dir['posts/*.*'].each do |path|
    markup = File.extname(path).downcase.gsub(/^\./,'')
    content = IO.read path
    first_line = content.match(/^(.*)\n/)[1]
    
    post_title = (first_line.match GitBlog::TitleRegexen[markup])[1]
    parsed = begin
      parser = GitBlog::Parsers.const_get(markup.gsub(/\b\w/){$&.upcase})
      out = parser.send :parse, content
      out
    end
    
    template = IO.read :design/:post.haml
    
    completed = Haml::Engine.new(template, :filename => :design/:post.haml).
      to_html(Object.new, {:content => parsed, :title => post_title})
    
    destination = path.gsub /.#{markup}$/, '.xhtml'
    file = File.open destination, File::RDWR|File::TRUNC|File::CREAT
    file.puts completed
    file.close
    puts "#{path} -> #{destination} (as #{markup})"
  end
end