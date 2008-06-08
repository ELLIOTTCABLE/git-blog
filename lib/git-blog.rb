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
  cp GitBlog::Location / :prepped / '.gitignore', '.'
  %w(welcome_to_your_git_blog.markdown .gitignore).each do |file|
    cp GitBlog::Location / :prepped / :posts / file, 'posts'
  end
  %w(main.css post.haml index.haml).each do |file|
    cp GitBlog::Location / :prepped / :design / file, 'design'
  end
  
  Dir['**/**'].each do |file|
    if File.directory? file
      chmod 0775, file
    else
      chmod 0664, file
    end
  end
  chmod 0755, '.git'
  chmod 0664, '.gitignore'
  chmod 0664, :posts / '.gitignore'
  
  blog.add
  blog.commit_all("A bird... no, a plane... no, a git-blog!")
end

desc 'Attach the blog to a GitHub repository - can also clone an existing git-blog repository here'
task :github, :user_name, :repo_name do |_, params|
  path = File.expand_path '.'
  user_name = params[:user_name].nil? ? %x(whoami).chomp : params[:user_name]
  repo_name = params[:repo_name].nil? ? File.basename(path) : params[:repo_name]
  
  github_url = "git@github.com:#{user_name.downcase}/#{repo_name.downcase}.git"
  
  if File.directory? File.join(path, 'posts') and
    (blog = Git.open path rescue false)
    
    github = blog.add_remote 'github', github_url
    blog.push github
  else
    system "git-init"
    system "git-remote add -f github #{github_url}"
    system "git checkout -b master github/master"
  end
end

desc 'Prepare the blog to be served (configures hooks)'
task :servable do
  should_be_initialized File.expand_path('.')
  
  mv '.git' / :hooks / 'post-receive', '.git' / :hooks / 'post-receive.old'
  cp GitBlog::Location / :prepped / 'post-receive.hook', '.git' / :hooks / 'post-receive'
  chmod 0775, '.git' / :hooks / 'post-receive'
  
  puts '** git-blog is prepared for serving (git post-recieve hook prepared)'
end

desc 'Create and open for editing a new post'
task :post do
  @resume = false
  temporary_post = :post_in_progress.markdown
  
  should_be_initialized File.expand_path('.')
  
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
    File.open temporary_post, File::RDWR|File::TRUNC|File::CREAT, 0664 do |post|
      post.puts  'Replace this text with your title!'
      post.puts  '=================================='
      post.print "\n"; post.close
    end
  end
  
  system "#{ENV['VISUAL']} #{temporary_post}"
  
  first_line = File.open(temporary_post, File::RDONLY).gets.chomp
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
  should_be_initialized File.expand_path('.')
  
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

# desc 'Invisible task, generates index.xhtml'
task :index do
  path = File.expand_path('.')
  repo = should_be_initialized path
  
  commits = repo.log.select {|c| c.message =~ /New post: /}
  posts = []
  commits.map do |commit|
    title = commit.message.match(/New post: (.*)$/)[1]
    posts << {:title => title, :slug => title.slugize}
  end
  
  template = IO.read :design / :index.haml
  
  completed = Haml::Engine.new(template, :filename => :design / :index.haml).
    to_html Object.new, :posts => posts
  
  destination = :index.xhtml
  file = File.open destination, File::RDWR|File::TRUNC|File::CREAT, 0664
  file.puts completed
  file.close
  puts "index.xhtml compiled"
end

desc 'Generate xhtml files from posts and design'
task :deploy => [:clobber, :index] do
  should_be_initialized File.expand_path('.')
  
  Dir['posts/*.*'].each do |path|
    markup = File.extname(path).downcase.gsub(/^\./,'')
    content = IO.read path
    first_line = content.match(/^(.*)\n/)[1]
    
    post_title = (first_line.match GitBlog::TitleRegexen[markup])[1]
    parsed = begin
      parser = GitBlog::Parsers.const_get(markup.gsub(/\b\w/){$&.upcase})
      parser.send :parse, content
    end
    
    template = IO.read :design / :post.haml
    
    completed = Haml::Engine.new(template, :filename => :design / :post.haml).
      to_html Object.new, {:content => parsed, :title => post_title}
    
    completed = GitBlog::Parsers::fix_pres(completed)
    
    destination = path.gsub /.#{markup}$/, '.xhtml'
    file = File.open destination, File::RDWR|File::TRUNC|File::CREAT, 0664
    file.puts completed
    file.close
    puts "#{path} -> #{destination} (as #{markup})"
  end
end


# desc 'Invisible task, forces checkout (for the post-receive hook)'
task :force_checkout do
  puts 'Forcing update of working copy...'
  system 'git-checkout -f master'
end

# desc 'Invisible task, run as the post-receive hook'
task :post_receive => [:force_checkout, :deploy]

def should_be_initialized path
  raise "** You haven't used `rake initialize` yet." unless
    File.directory? File.join(path, 'posts') and
    (blog = Git.open path rescue false)
  blog
end