
# @return [Array<String>] The list of the names of the CocoaPods repositories
#         which store a gem.
#
GEM_REPOS = %w[
  CLAide
  CocoaPods
  Core
  Xcodeproj
  cocoapods-docs
  cocoapods-downloader
  cocoapods-podfile_info
  cocoapods-try
]

# Task set-up
#-----------------------------------------------------------------------------#

desc "Clones all the CocoaPods repositories"
task :set_up do
  Rake::Task[:clone].invoke
  Rake::Task[:bootstrap].invoke
end

# Task clone
#-----------------------------------------------------------------------------#

desc "Clones the GEM repositories"
task :clone do
  repos = fetch_gem_repos
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

# Task bootstrap
#-----------------------------------------------------------------------------#

desc "Runs the Bootstrap task on all the repositories"
task :bootstrap do
  title "Bootstrapping all the repositories"
  Dir['*/'].each do |dir|
    Dir.chdir(dir) do
      subtitle "\nBootstrapping #{dir}"
      if File.exist?('Rakefile')
        has_bootstrap_task = `rake --no-search --tasks bootstrap`.include?('rake bootstrap')
        if has_bootstrap_task
          sh "rake --no-search bootstrap"
        end
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
  repos = fetch_gem_repos
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
  Dir['*/'].each do |dir|
    Dir.chdir(dir) do
      subtitle "\nPulling #{dir}"
      sh "git pull"
      sh "git submodule update"
    end
  end
end

# Task set_up_local_dependencies
#-----------------------------------------------------------------------------#

desc "Setups the repositories to use their dependencies from the checkouts (Bundler Local Git Repos feature)"
task :set_up_local_dependencies do
  title "Setting up Bundler's Local Git Repos"
  GEM_REPOS.each do |gem_name|
    sh "bundle config local.#{gem_name} ./#{gem_name}"
  end
end

# Task status
#-----------------------------------------------------------------------------#

desc "Checks the gems which need a release"
task :status do
  title "Checking status"
  dirs = Dir['*/'].map { |dir| dir[0...-1] }

  subtitle "Repositories not in master branch"
  dirs_not_in_master = dirs.reject do |dir|
    Dir.chdir(dir) do
      branch = `git rev-parse --abbrev-ref HEAD`.chomp
      branch == 'master'
    end
  end
  if dirs_not_in_master.empty?
    puts "All repos are on the master branch"
  else
    puts "- #{dirs_not_in_master.join("\n- ")}"
  end

  subtitle "\nRepositories with a dirty working copy"
  dirty_dirs = dirs.reject do |dir|
    Dir.chdir(dir) do
      `git diff --quiet`
      exit_status = $?.exitstatus
      `git diff --cached --quiet`
      cached_exit_status = $?.exitstatus
      exit_status.zero? && cached_exit_status.zero?
    end
  end
  if dirty_dirs.empty?
    puts "All the repositories have a clean working copy"
  else
    puts "- #{dirty_dirs.join("\n- ")}"
  end

  subtitle "\nGems with releases"
  gemspecs = Dir['*/*.gemspec']
  gem_dirs = gemspecs.map { |path| File.dirname(path) }.uniq
  has_pending_releases = false
  name_commits_tags = gem_dirs.map do |dir|
    Dir.chdir(dir) do
      tag = `git describe --abbrev=0 2>/dev/null`.chomp
      if tag != ''
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


# Release
#-----------------------------------------------------------------------------#

desc "Run all specs, build and install gem, commit version change, tag version change, and push everything"
task :release, :gem_dir do |t, args|
  require 'pathname'
  require 'date'

  unless ENV["BUNDLE_GEMFILE"].nil?
    error("This task is not supported under bundle exec")
    exit 1
  end

  gem_dir = Pathname(args[:gem_dir])
  gem_version = gem_version(gem_dir)
  title "Releasing #{gem_dir} #{gem_version}"
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

    subtitle "Building the Gem"
    sh 'rake build'

    subtitle "Testing gem installation (tmp/gems)"
    gem_filename = Pathname('pkg') + "#{gem_basename(gem_dir)}-#{gem_version}.gem"
    tmp = File.expand_path('../tmp', __FILE__)
    tmp_gems = File.join(tmp, 'gems')
    silent_sh "rm -rf '#{tmp}'"
    sh "gem install --install-dir='#{tmp_gems}' #{gem_filename}"

    # Then release
    sh "git commit -a -m 'Release #{gem_version}'"
    sh "git tag -a #{gem_version} -m 'Release #{gem_version}'"
    sh "git push origin master"
    sh "git push origin --tags"
    sh "gem push #{gem_filename}"
  end
end



#-----------------------------------------------------------------------------#
# HELPERS
#-----------------------------------------------------------------------------#

# Repos Helpers
#-----------------------------------------------------------------------------#

# @return [Array<Hash>] The list of the CocoaPods repositories which contain a
# Gem as returned by the GitHub API.
#
def fetch_gem_repos
  fetch_repos.select do |repo|
    GEM_REPOS.include?(repo['name'])
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
  response = open(url).read
  repos = JSON.parse(response)
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
    subtitle "\nCloning #{name}"
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

    if `git tag`.strip.split("\n").include?(version)
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
  end

  unless errors.empty?
    errors.each do |error|
      $stderr.puts(red("[!] #{error}"))
    end
    exit 1
  end
end

# Gem Helpers
#-----------------------------------------------------------------------------#

def gem_version(gem_dir)
  spec_name = gem_basename(gem_dir) + ".gemspec"
  spec_path =  gem_dir + spec_name
  spec = Gem::Specification::load(spec_path.to_s)
  gem_version = spec.version
end

def gem_basename(gem_dir)
  gem_dir.to_s.downcase
end

# Other Helpers
#-----------------------------------------------------------------------------#

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
  puts
end

def subtitle(string)
  puts green(string)
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

def cyan(string)
  "\033[0;36m#{string}\033[0m"
end

