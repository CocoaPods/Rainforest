
# @return [Array<String>] The list of the names of the CocoaPods repositories
#         which store a gem or are related to the development of the gems.
#
# @note   The order is from more important to less important and consequently
#         the gems at the bottom are dependencies of the gems at the top.
#
GEM_REPOS = %w[
  CocoaPods
  Core
  Xcodeproj
  CLAide
  VersionKit
  cocoapods-docs
  cocoapods-downloader
  cocoapods-plugins
  cocoapods-podfile_info
  cocoapods-try
]

# @return [Array<String>] The list of the repos contains "template" contents
#         to be used as a model.
#
# @note Such repositories will be excluded from tasks like bootstrap_repos
#       to avoid running `rake` on them, as their Rakefile are not intended
#       to be used in-place in the repository, but only to serve as a model.
#
TEMPLATE_REPOS = %w[
  pod-template
  shared
]

# @return [Array<String>] The list of the repos which should be cloned by
#         default.
#
DEFAULT_REPOS = GEM_REPOS + TEMPLATE_REPOS

task :default => :status

# Task bootstrap / set-up
#-----------------------------------------------------------------------------#

desc "Clones all the CocoaPods repositories"
task :bootstrap do
  if system('which bundle')
    Rake::Task[:clone].invoke
    Rake::Task[:bootstrap_repos].invoke
  else
    $stderr.puts "\033[0;31m" \
      "[!] Please install the bundler gem manually:\n" \
      "    $ [sudo] gem install bundler" \
      "\e[0m"
    exit 1
  end
end


begin
  
  # Task clone
  #-----------------------------------------------------------------------------#
  
  desc "Clones the GEM repositories"
  task :clone do
    repos = fetch_default_repos
    title "Cloning the GEM repositories"
    clone_repos(repos)
  end
  
  # Task clone_all
  #-----------------------------------------------------------------------------#
  
  desc "Clones ALL the CocoaPods repositories"
  task :clone_all do
    repos = fetch_repos
    title "Cloning gem repositories"
    clone_repos(repos)
  end
  
  # Task bootstrap_repos
  #-----------------------------------------------------------------------------#
  
  desc "Runs the Bootstrap task on all the repositories"
  task :bootstrap_repos do
    title "Bootstrapping all the repositories"
    rakefile_repos.each do |dir|
      Dir.chdir(dir) do
        subtitle "Bootstrapping #{dir}"
        if has_rake_task?('bootstrap')
          sh "rake --no-search bootstrap"
        end
      end
    end
  
    disk_usage = `du -h -c -d 0`.split(' ').first
    puts "\nDisk usage: #{disk_usage}"
  end
  
  # Task switch_to_ssh
  #-----------------------------------------------------------------------------#
  
  desc "Points the origin remote of all the git repos to use the SSH URL"
  task :switch_to_ssh do
    repos = fetch_default_repos
    title "Setting SSH URLs"
    repos.each do |repo|
      name = repo['name']
      url = repo['ssh_url']
      subtitle(name)
      Dir.chdir(name) do
        sh "git remote set-url origin '#{url}'"
      end
    end
  end
  
  # Task pull
  #-----------------------------------------------------------------------------#
  
  desc "Pulls all the repositories & updates their submodules"
  task :pull do
    title "Pulling all the repositories"
    subtitle "Pulling Rainforest"
    sh "git pull --no-commit"
  
    updated_repos = []
    repos.each do |dir|
      Dir.chdir(dir) do
        subtitle "Pulling #{dir}"
        sh "git remote update"
        status = `git status -uno`
        unless status.include?('up-to-date') || status.include?('ahead')
          updated_repos << dir
          sh "git pull --no-commit"
          sh "git submodule update"
        end
      end
    end
  
    unless updated_repos.empty?
      title "Summary"
      updated_repos.each do |dir|
        subtitle dir
        Dir.chdir(dir) do
          puts `git log ORIG_HEAD..`
        end
      end
    end
  end
  
  desc "Gets the count of the open issues"
  task :issues do
    require 'open-uri'
    require 'json'
  
    title 'Fetching open issues'
    GEM_REPOS.each do |name|
      url = "https://api.github.com/repos/CocoaPods/#{name}/issues?state=open&per_page=100"
      response = open(url).read
      issues = JSON.parse(response)
      next if issues.empty?
  
      pull_requests = issues.select { |issue| issue.has_key?('pull_request') }
      subtitle name
      if issues.count == 100
        puts "100 or more open issues"
      else
        puts "#{issues.count} open issues"
      end
  
      unless pull_requests.empty?
        puts "#{pull_requests.count} pull requests"
      end
    end
  end
  
  # Task local_dependencies_set
  #-----------------------------------------------------------------------------#
  
  desc "Configure the repositories to use their dependencies from the rainforest (Bundler Local Git Repos feature)"
  task :local_dependencies_set do
    title "Setting up Bundler's Local Git Repos"
    GEM_REPOS.each do |repo|
      spec = spec(repo)
      sh "bundle config local.#{spec.name} ./#{repo}"
    end
  
    subtitle "Building Xcodeproj native extensions"
    puts "NOTE: This step needs to be performed every-time the extension are" \
      " modified."
    Dir.chdir('Xcodeproj') do
      sh "rake ext:cleanbuild"
    end
  end
  
  # Task local_dependencies_unset
  #-----------------------------------------------------------------------------#
  
  desc "Configure the repositories to use their dependencies from the git remotes"
  task :local_dependencies_unset do
    title "Setting up Bundler's Local Git Repos"
    GEM_REPOS.each do |repo|
      spec = spec(repo)
      Dir.chdir(repo) do
        sh "bundle config --delete local.#{spec.name}"
      end
    end
  end
  
  # Task status
  #-----------------------------------------------------------------------------#
  
  desc "Prints the repositories with un-merged branches or a dirty working copy and lists the gems with commits after the last release."
  task :status do
    title "Checking status"
  
    dirs_not_in_master = repos.reject do |dir|
      Dir.chdir(dir) do
        branch = `git rev-parse --abbrev-ref HEAD`.chomp
        ['master', 'develop'].include?(branch)
      end
    end
  
    unless dirs_not_in_master.empty?
      subtitle "Repositories not in master/develop branch"
      puts "- #{dirs_not_in_master.join("\n- ")}"
    end
  
    dirs_with_unmerged_branches = repos.map do |dir|
      Dir.chdir(dir) do
        base_branch = default_branch
        branches = git_branch_list(" --no-merged #{base_branch}")
        unless branches.empty?
          "#{dir}: #{branches.join(', ')}"
        end
      end
    end.compact
  
    unless dirs_with_unmerged_branches.empty?
      subtitle "Repositories with un-merged branches"
      puts "- #{dirs_with_unmerged_branches.join("\n- ")}"
    end
  
    dirty_dirs = repos.reject do |dir|
      Dir.chdir(dir) do
        `git diff --quiet`
        exit_status = $?.exitstatus
        `git diff --cached --quiet`
        cached_exit_status = $?.exitstatus
        exit_status.zero? && cached_exit_status.zero?
      end
    end
  
    unless dirty_dirs.empty?
      subtitle "Repositories with a dirty working copy"
      puts "- #{dirty_dirs.join("\n- ")}"
    end
  
    subtitle "Gems with releases"
    has_pending_releases = false
    name_commits_tags = gem_dirs.map do |dir|
      tag = last_tag(dir)
      if tag != ''
        Dir.chdir(dir) do
          commits_since_last_tag = `git rev-list #{tag}..HEAD --count`.chomp.to_i
          unless commits_since_last_tag.zero?
            has_pending_releases = true
            [dir, commits_since_last_tag, tag]
          end
        end
      end
    end
    name_commits_tags = name_commits_tags.compact.sort_by { |value| value[1] }.reverse
    name_commits_tags.each do |name_commits_tag|
      puts "\n- #{name_commits_tag[0]}\n  #{name_commits_tag[1]} commits since #{name_commits_tag[2]}"
    end
  
    unless has_pending_releases
      puts "All the gems are up to date"
    end
  end
  
  # Task clean-up
  #-----------------------------------------------------------------------------#
  
  desc "Performs safe clean-up operations"
  task :cleanup do
    title "Cleaning up"
    cleaned = false
    repos.each do |repo|
      Dir.chdir(repo) do
        base_branch = default_branch
        if base_branch
          merged_branches =  git_branch_list("--merged #{base_branch}")
          merged_branches.delete(base_branch)
          unless merged_branches.count.zero?
            subtitle repo
            merged_branches.each do |merged_brach|
              cleaned = true
              sh "git branch -d #{merged_brach}"
            end
          end
        else
          subtitle repo
          puts "Skipping because default branch could not be found: #{branches}"
        end
      end
    end
  
    unless cleaned
      puts "Nothing to clean"
    end
  end
  
  
  # Task versions
  #-----------------------------------------------------------------------------#
  
  desc "Prints the last released version of every gem"
  task :versions do
    title "Printing versions"
    GEM_REPOS.each do |dir|
      begin
      spec = spec(dir)
      subtitle spec.name
      puts spec.version
      rescue
        next
      end
    end
  end
  
  # Task Release
  #-----------------------------------------------------------------------------#
  
  # The pre_release and post_release tasks are called in the Rakefiles of the
  # gems.
  #
  # FEATURES:
  # - Dependencies are checked through the installation of the gem.
  #
  # TODO:
  # - Should the bundles be updated?
  #
  desc "Run all specs, build and install gem, commit version change, tag version change, and push everything"
  task :release, :gem_dir do |t, args|
    require 'pathname'
    require 'date'
  
    unless ENV["BUNDLE_GEMFILE"].nil?
      error("This task is not supported under bundle exec")
      exit 1
    end
  
    gem_dir = Pathname(args[:gem_dir])
    gem_name = gem_name(gem_dir)
    gem_version = gem_version(gem_dir)
    title "Releasing #{gem_name} #{gem_version} (from #{last_tag(gem_dir)})"
    unless ENV['SKIP_CHECKS']
      check_repo_for_release(gem_dir, gem_version)
      print "You are about to release `#{gem_version}`, is that correct? [y/n] "
      exit 1 if $stdin.gets.strip.downcase != 'y'
    end
  
    Dir.chdir(gem_dir) do
      subtitle "Updating the repo"
      sh 'git pull'
  
      subtitle "Running specs"
      sh 'bundle exec rake spec'
  
      if has_rake_task?('pre_release')
        subtitle "Running pre-release task"
        sh 'rake pre_release'
      end
  
      subtitle "Building the Gem"
      sh 'rake build'
  
      subtitle "Testing gem installation (tmp/gems)"
      gem_filename = Pathname('pkg') + "#{gem_name}-#{gem_version}.gem"
      tmp = File.expand_path('../tmp', __FILE__)
      tmp_gems = File.join(tmp, 'gems')
      silent_sh "rm -rf '#{tmp}'"
      sh "gem install --install-dir='#{tmp_gems}' #{gem_filename}"
  
      subtitle "Commiting, tagging & Pushing"
      sh "git commit -a -m 'Release #{gem_version}'"
      sh "git tag -a #{gem_version} -m 'Release #{gem_version}'"
      sh "git push origin master"
      sh "git push origin --tags"
  
      subtitle "Releasing the Gem"
      sh "gem push #{gem_filename}"
  
      if has_rake_task?('post_release')
        subtitle "Running post_release task"
        sh 'rake post_release'
      end
    end
  end

rescue LoadError
  $stderr.puts "\033[0;31m" \
    '[!] Some Rake tasks haven been disabled because the environment' \
    ' couldn’t be loaded. Be sure to run `rake bootstrap` first.' \
    "\e[0m"
end

#-----------------------------------------------------------------------------#
# HELPERS
#-----------------------------------------------------------------------------#

# Repos Helpers
#-----------------------------------------------------------------------------#

# @return [Array<Hash>] The list of the CocoaPods repositories which contain a
# Gem as returned by the GitHub API.
#
def fetch_default_repos
  fetch_repos.select do |repo|
    DEFAULT_REPOS.include?(repo['name'])
  end
end

# @return [Array<Hash>] The list of the CocoaPods repositories as returned by
# the GitHub API.
#
def fetch_repos
  require 'json'
  require 'open-uri'
  title "Fetching repositories list"
  url = 'https://api.github.com/orgs/CocoaPods/repos?type=public'
  repos = []
  loop do
    file = open(url)
    response = file.read
    repos.concat(JSON.parse(response))

    link = Array(file.meta['link']).first
    if match = link.match(/<(.*)>; rel="next"/)
      url = match.captures.first
    else
      break
    end
  end

  repos.reject! { |repo| repo['name'] == 'Rainforest' }
  puts "Found #{repos.count} public repositories"
  repos
end

# Clones the given repos to a directory named after themselves unless the
# directory already exists.
#
# @param  [Array<Hash>] The description of the repositories.
#
# @return [void]
#
def clone_repos(repos)
  repos.each do |repo|
    name = repo['name']
    subtitle "Cloning #{name}"
    url = repo['clone_url']
    if File.exist?(name)
      puts "Already cloned"
    else
      sh "git clone #{url}"
    end
  end
end

# Checks the given repo for a release and fails the task if any issue exits
# listing them.
#
# @param [String] gem_dir The repo to check.
# @param [String] version The version which should be released.
#
def check_repo_for_release(repo_dir, version)
  errors = []
  Dir.chdir(repo_dir) do
    if `git symbolic-ref HEAD 2>/dev/null`.strip.split('/').last != 'master'
      errors << "You need to be on the `master` branch in order to do a release."
    end

    if `git tag`.strip.split("\n").include?(version.to_s)
      errors << "A tag for version `#{version}` already exists."
    end

    diff_lines = `git diff --name-only`.strip.split("\n")

    if diff_lines.size == 0
      errors << "Change the version number of the gem yourself"
    end

    diff_lines.delete('Gemfile.lock')
    diff_lines.delete('CHANGELOG.md')
    unless diff_lines.count == 1
      # TODO Check that is only the version file changed
      error = "Only change the version, the CHANGELOG.md and the Gemfile.lock files"
      error << "\n- " + diff_lines.join("\n- ")
      errors << error
    end

    unless Pathname.new('CHANGELOG.md').read.lines.include?("## #{version}\n")
      errors << "The CHANGELOG.md doesn't include the released version " \
        "`## #{version}`.Update it manually."
    end
  end

  unless errors.empty?
    errors.each do |error|
      $stderr.puts(red("[!] #{error}"))
    end
    exit 1
  end
end

# @return [Array<String>] All the checked out repos
#
def repos
  result = Dir['*/'].map { |dir| dir[0...-1] }
  # TODO get rid of the extension dir
  result.reject{ |repo| repo == 'extensions' }
end

# @return [Array<String>] All the directories that contains a Rakefile,
#         except those in TEMPLATE_REPOS which should be excluded
#
def rakefile_repos
  Dir['*/Rakefile'].map { |file| File.dirname(file) }
end

# @return [Array<String>]
#
def git_branch_list(arguments = nil)
  branches = `git branch #{arguments}`.split("\n")
  branches.map { |line| line.split(' ').last }
end

def default_branch
  default_branches = ['master', 'develop']
  branches = git_branch_list
  common = branches & default_branches
  if common.count == 1
    common.first
  end
end

# Gem Helpers
#-----------------------------------------------------------------------------#

# @return [Array<String>] the directory of the gems.
#
def gem_dirs
  gemspecs = Dir['*/*.gemspec']
  gemspecs.map { |path| File.dirname(path) }.uniq
end

def spec(gem_dir)
  files = Dir.glob("#{gem_dir}/*.gemspec")
  unless files.count == 1
    error("Unable to select a gemspec in #{gem_dir}")
  end
  spec_path = files.first
  spec = Gem::Specification::load(spec_path.to_s)
end

def gem_version(gem_dir)
  spec(gem_dir).version
end

def gem_name(gem_dir)
  spec(gem_dir).name
end

def last_tag(dir)
  Dir.chdir(dir) do
    `git describe --abbrev=0 2>/dev/null`.chomp
  end
end

# Other Helpers
#-----------------------------------------------------------------------------#

# @return [Bool] Wether the Rakefile in the current working directory has a
#         task with the given name.
#
def has_rake_task?(task)
  `rake --no-search --tasks #{task}`.include?("rake #{task}")
end

def silent_sh(command)
  require 'english'
  output = `#{command} 2>&1`
  unless $CHILD_STATUS.success?
    puts output
    exit 1
  end
  output
end

# UI
#-----------------------------------------------------------------------------#

# Prints a title.
#
def title(string)
  puts
  puts "-" * 80
  puts cyan(string)
  puts "-" * 80
end

def subtitle(string)
  puts "\n#{green(string)}"
end

def error(string)
  raise red("[!] #{string}")
end

# Colorizes a string to green.
#
def green(string)
  "\033[0;32m#{string}\e[0m"
end

# Colorizes a string to yellow.
#
def yellow(string)
  "\033[0;33m#{string}\e[0m"
end

# Colorizes a string to red.
#
def red(string)
  "\033[0;31m#{string}\e[0m"
end

# Colorizes a string to cyan.
#
def cyan(string)
  "\033[0;36m#{string}\033[0m"
end

