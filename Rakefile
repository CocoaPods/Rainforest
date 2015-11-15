# encoding: utf-8

# @return [Array<String>] The list of the names of the CocoaPods repositories
#         which store a gem or are related to the development of the gems.
#
# @note   The order is from more important to less important and consequently
#         the gems at the bottom are dependencies of the gems at the top.
#
GEM_REPOS = %w(
  CLAide
  claide-completion
  CocoaPods
  cocoapods-deintegrate
  cocoapods-docs
  cocoapods-downloader
  cocoapods-plugins
  cocoapods-search
  cocoapods-stats
  cocoapods-trunk
  cocoapods-try
  Core
  Cork
  Molinillo
  Xcodeproj
)

# @return [Array<String>] The list of the repos contains "template" contents
#         to be used as a model.
#
# @note Such repositories will be excluded from tasks like bootstrap_repos
#       to avoid running `rake` on them, as their Rakefile are not intended
#       to be used in-place in the repository, but only to serve as a model.
#
TEMPLATE_REPOS = %w(
  pod-template
  shared
)

# @return [Array<String>] The list of the repos which should be cloned by
#         default.
#
DEFAULT_REPOS = GEM_REPOS + TEMPLATE_REPOS

task :default => :status

# Task bootstrap / set-up
#-----------------------------------------------------------------------------#

desc 'Clones all the CocoaPods repositories'
task :bootstrap do
  if system('which bundle')
    Rake::Task[:clone].invoke
    Rake::Task[:bootstrap_repos].invoke
  else
    $stderr.puts "\033[0;31m" \
      "[!] Please install the bundler gem manually:\n" \
      '    $ [sudo] gem install bundler' \
      "\e[0m"
    exit 1
  end
end

begin

  # Task clone
  #-----------------------------------------------------------------------------#

  desc 'Clones the GEM repositories'
  task :clone do
    repos = fetch_default_repos
    title 'Cloning the GEM repositories'
    clone_repos(repos)
  end

  # Task clone_all
  #-----------------------------------------------------------------------------#

  desc 'Clones ALL the CocoaPods repositories'
  task :clone_all do
    repos = fetch_repos
    title 'Cloning gem repositories'
    clone_repos(repos)
  end

  # Task bootstrap_repos
  #-----------------------------------------------------------------------------#

  desc 'Runs the Bootstrap task on all the repositories'
  task :bootstrap_repos do
    title 'Bootstrapping all the repositories'
    rakefile_repos.each do |dir|
      Dir.chdir(dir) do
        subtitle "Bootstrapping #{dir}"
        sh 'rake --no-search bootstrap' if rake_task?('bootstrap')
      end
    end

    disk_usage = `du -h -c -d 0`.split(' ').first
    puts "\nDisk usage: #{disk_usage}"
  end

  # Task switch_to_ssh
  #-----------------------------------------------------------------------------#

  desc 'Points the origin remote of all the git repos to use the SSH URL'
  task :switch_to_ssh do
    repos = fetch_default_repos
    title 'Setting SSH URLs'
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

  desc 'Pulls all the repositories & updates their submodules'
  task :pull do
    title 'Pulling all the repositories'
    if pull_current_repo(false)
      puts yellow("\n[!] The Rainforest repository itself has been updated.\n" \
           "You should run `rake bootstrap` to update all repositories\n" \
           'and fetch the potentially new ones.')
    else
      updated_repos = []
      repos.each do |dir|
        Dir.chdir(dir) do
          updated = pull_current_repo(true)
          updated_repos << dir if updated
        end
      end

      unless updated_repos.empty?
        title 'Summary'
        updated_repos.each do |dir|
          subtitle dir
          Dir.chdir(dir) do
            puts `git log ORIG_HEAD..`
          end
        end
      end
    end
  end

  desc 'Gets the count of the open issues'
  task :issues do
    require 'open-uri'
    require 'json'

    title 'Fetching open issues'
    GEM_REPOS.dup.push('Rainforest').each do |name|
      url = "https://api.github.com/repos/CocoaPods/#{name}/issues?state=open&per_page=100&#{github_access_token_query}"
      response = open(url).read
      issues = JSON.parse(response)

      pure_issues = issues.reject { |issue| issue.key?('pull_request') }
      pull_requests = issues.select { |issue| issue.key?('pull_request') }
      puts cyan("\n#{name}")

      if issues.empty?
        puts green 'Awesome no open issues'
      else
        unless pull_requests.empty?
          if pull_requests.count == 1
            puts yellow('1 pull request')
          elsif pull_requests.count > 1
            puts yellow("#{pull_requests.count} pull requests")
          end

          if pull_requests.count <= 5
            puts pull_requests.map { |i| '- ' + i['title'] }
          end
        end

        if pure_issues.count == 100
          puts yellow('100 or more open issues')
        elsif pure_issues.count == 1
          puts yellow('1 open issue')
        elsif pure_issues.count > 1
          puts yellow("#{pure_issues.count} open issues")
        end

        puts pure_issues.map { |i| '- ' + i['title'] } if pure_issues.count <= 5
      end
    end
  end

  # Task local_dependencies_set
  #-----------------------------------------------------------------------------#

  desc 'Configure the repositories to use their dependencies from the rainforest (Bundler Local Git Repos feature)'
  task :local_dependencies_set do
    title "Setting up Bundler's Local Git Repos"
    GEM_REPOS.each do |repo|
      spec = spec(repo)
      sh "bundle config local.#{spec.name} ./#{repo}"
    end
  end

  # Task local_dependencies_unset
  #-----------------------------------------------------------------------------#

  desc 'Configure the repositories to use their dependencies from the git remotes'
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

  desc 'Prints the repositories with un-merged branches or a dirty working copy and lists the gems with commits after the last release.'
  task :status do
    title 'Checking status'

    dirs_not_in_master = repos.reject do |dir|
      Dir.chdir(dir) do
        branch = `git rev-parse --abbrev-ref HEAD`.chomp
        %w(master develop).include?(branch)
      end
    end

    unless dirs_not_in_master.empty?
      subtitle 'Repositories not in master/develop branch'
      puts "- #{dirs_not_in_master.join("\n- ")}"
    end

    dirs_with_unmerged_branches = repos.map do |dir|
      Dir.chdir(dir) do
        base_branch = default_branch
        branches = git_branch_list(" --no-merged #{base_branch}")
        "#{dir}: #{branches.join(', ')}" unless branches.empty?
      end
    end.compact

    unless dirs_with_unmerged_branches.empty?
      subtitle 'Repositories with un-merged branches'
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
      subtitle 'Repositories with a dirty working copy'
      puts "- #{dirty_dirs.join("\n- ")}"
    end

    subtitle 'Gems with releases'
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

    puts 'All the gems are up to date' unless has_pending_releases
  end

  # Task clean-up
  #-----------------------------------------------------------------------------#

  desc 'Performs safe clean-up operations'
  task :cleanup do
    title 'Cleaning up'
    cleaned = false
    repos.each do |repo|
      Dir.chdir(repo) do
        base_branch = default_branch
        if base_branch
          merged_branches = git_branch_list("--merged #{base_branch}")
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

    puts 'Nothing to clean' unless cleaned
  end

  # Task versions
  #-----------------------------------------------------------------------------#

  desc 'Prints the last released version of every gem'
  task :versions do
    title 'Printing versions'
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

  # TODO: Should the bundles be updated?
  #
  desc 'Releases a gem: https://github.com/CocoaPods/Rainforest/wiki'
  task :release, :gem_dir do |_t, args|
    require 'pathname'
    require 'date'

    unless ENV['BUNDLE_GEMFILE'].nil?
      error('This task is not supported under bundle exec')
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

    if github_access_token
      gem 'nap'
      require 'rest'
      require 'json'
    else
      error 'You have not provided a github access token via `.github_access_token`, ' \
       'so a GitHub release cannot be made automatically.'
    end

    Dir.chdir(gem_dir) do
      subtitle 'Updating the repo'
      sh 'git pull --no-rebase'

      subtitle 'Running specs'
      sh 'bundle exec rake spec'

      subtitle 'Adding release date to CHANGELOG'
      changelog = File.read('CHANGELOG.md')
      changelog.sub!("## #{gem_version}\n") { |_s| "## #{gem_version} (" << Time.now.utc.strftime('%F') << ")\n" }
      File.open('CHANGELOG.md', 'w') { |f| f << changelog }

      if rake_task?('pre_release')
        subtitle 'Running pre-release task'
        sh 'bundle exec rake pre_release'
      end

      subtitle 'Validating the gemspec'
      validate_spec(spec('.'))

      subtitle 'Building the Gem'
      sh 'bundle exec rake build'

      subtitle 'Testing gem installation (tmp/gems)'
      gem_filename = Pathname('pkg') + "#{gem_name}-#{gem_version}.gem"
      tmp = File.expand_path('../tmp', __FILE__)
      tmp_gems = File.join(tmp, 'gems')
      silent_sh "rm -rf '#{tmp}'"
      sh "gem install --install-dir='#{tmp_gems}' #{gem_filename}"

      subtitle 'Commiting, tagging & Pushing'
      sh "git commit -a -m 'Release #{gem_version}'"
      sh "git tag -a #{gem_version} -m 'Release #{gem_version}'"
      sh 'git push origin master'
      sh 'git push origin --tags'

      subtitle 'Releasing the Gem'
      sh "gem push #{gem_filename}"

      if rake_task?('post_release')
        subtitle 'Running post_release task'
        sh 'bundle exec rake post_release'
      end
    end

    if github_access_token
      subtitle 'Making GitHub release'
      make_github_release(gem_dir, gem_version, gem_version.to_s, github_access_token)
      `open https://github.com/CocoaPods/#{gem_dir}/releases/#{gem_version}`
    end

    `open https://rubygems.org/gems/#{gem_name}`
  end

  # Task Update RuboCop configuration
  #-----------------------------------------------------------------------------#

  desc 'Update the shared CocoaPods RuboCop configuration for the given repo or for all the repos'
  task :update_rubocop_configuration, :gem_dir do |_t, args|
    repo = {
      'name' => 'shared',
      'clone_url' => 'https://github.com/CocoaPods/shared.git',
    }
    clone_repos([repo]) unless File.exist?('shared')

    if args[:gem_dir]
      dirs = [args[:gem_dir]]
    else
      dirs = gem_dirs
    end

    has_changes = false
    dirs.each do |gem_dir|
      FileUtils.cp('./shared/.rubocop_cocoapods.yml', gem_dir)
      Dir.chdir(gem_dir) do
        diff_lines = `git diff --name-only`.strip.split("\n")
        if diff_lines.include?('.rubocop-cocoapods.yml')
          puts green("- #{gem_dir}")
          has_changes = true
        end
      end
    end

    puts "\nCommit manually to the above repos" if has_changes
  end

  #-- Spec -------------------------------------------------------------------#

  desc 'Run all specs of all the gems'
  task :spec do
    title 'Running specs'
    GEM_REPOS.reverse_each do |repo|
      Dir.chdir(repo) do
        subtitle repo
        sh 'bundle exec rake spec'
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
  title 'Fetching repositories list'
  url = "https://api.github.com/orgs/CocoaPods/repos?type=public&#{github_access_token_query}"
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
      puts 'Already cloned'
    else
      sh "git clone #{url} --depth 1 --recursive"
    end
  end
end

# Pull the repo in the current working directory
#
# @param [Bool] Whether we want to update the submodules as well
#
# @return [Bool] true if the repo has updates that were pulled
#                false if there was nothing to update (repo already up-to-date or ahead)
#
def pull_current_repo(update_submodules)
  subtitle "Pulling #{File.basename(Dir.getwd)}"
  sh 'git remote update'
  status = `git status -uno`
  unless status.include?('up-to-date') || status.include?('ahead')
    sh 'git pull --no-commit'
    sh 'git submodule update' if update_submodules
    return true
  end
  false
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
    if `git symbolic-ref HEAD 2>/dev/null`.strip.split('/').last !~ /(\Amaster)|(-stable)\Z/
      errors << 'You need to be on the `master` branch or a `stable` branch in order to do a release.'
    end

    if `git tag`.strip.split("\n").include?(version.to_s)
      errors << "A tag for version `#{version}` already exists."
    end

    diff_lines = `git diff --name-only`.strip.split("\n")

    if diff_lines.size == 0
      errors << 'Change the version number of the gem yourself'
    end

    diff_lines.delete('Gemfile.lock')
    diff_lines.delete('CHANGELOG.md')
    unless diff_lines.count == 1
      # TODO: Check that is only the version file changed
      error = 'Only change the version, the CHANGELOG.md and the Gemfile.lock files'
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
  Dir['*/'].map { |dir| dir[0...-1] }
end

# @return [Array<String>] All the directories that contains a Rakefile,
#         except those in TEMPLATE_REPOS, which should be excluded
#
def rakefile_repos
  Dir['*/Rakefile'].map { |file| File.dirname(file) } - TEMPLATE_REPOS
end

# @return [Array<String>]
#
def git_branch_list(arguments = nil)
  branches = `git branch #{arguments}`.split("\n")
  branches.map { |line| line.split(' ').last }
end

def default_branch
  default_branches = %w(master develop)
  branches = git_branch_list
  common = branches & default_branches
  common.first if common.count == 1
end

def make_github_release(repo, version, tag, access_token)
  body = changelog_for_repo(repo, version)

  REST.post("https://api.github.com/repos/CocoaPods/#{repo}/releases?access_token=#{access_token}",
            {
              :tag_name => tag,
              :name => version.to_s,
              :body => body,
              :prerelease => version.prerelease?,
            }.to_json,
            {
              'Content-Type' => 'application/json',
              'User-Agent' => 'runscope/0.1,segiddins',
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip, deflate',
            },
           )
end

def changelog_for_repo(repo, version)
  changelog_path = File.expand_path('CHANGELOG.md', repo)
  if File.exist?(changelog_path)
    title_token = '## '
    current_verison_title = title_token + version.to_s
    text = File.open(changelog_path, 'r:UTF-8', &:read)
    lines = text.split("\n")

    current_version_index = lines.find_index { |line| line.strip =~ /^#{current_verison_title}($|\b)/ }
    unless current_version_index
      raise "Update the changelog for the last version (#{version})"
    end
    current_version_index += 1
    previous_version_lines = lines[(current_version_index + 1)...-1]
    previous_version_index = current_version_index + (
      previous_version_lines.find_index { |line| line.start_with?(title_token) && !%w(rc beta).any? { |pre| line.include?(pre) } } ||
      lines.count
    )

    relevant = lines[current_version_index..previous_version_index]

    relevant.join("\n").strip
  end
end

def github_access_token
  begin
    Pathname('.github_access_token').expand_path.read.strip
  rescue
    nil
  end
end

def github_access_token_query
  if token = github_access_token
    "access_token=#{token}"
  else
    ''
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
  error("Unable to select a gemspec in #{gem_dir}") unless files.count == 1
  spec_path = files.first
  Gem::Specification.load(spec_path.to_s)
end

def validate_spec(spec)
  spec = spec.dup
  Dir.chdir(File.dirname spec.loaded_from) do
    def spec.alert_warning(warning)
      return if warning =~ /prerelease dependency/
      return if warning =~ /no description specified/
      return if warning =~ %r{See http://guides.rubygems.org/specification-reference/ for help}
      return if warning =~ /no email specified/
      return if warning =~ /open-ended dependency/
      return if warning =~ /pessimistic dependency on .* overly strict/
      (@warning_messages ||= []) << warning
    end
    spec.validate(false)
    warnings = spec.instance_variable_get(:@warning_messages)
    if warnings && !warnings.empty?
      error "'#{spec.name}' failed to validate due to warnings:\n\n" << warnings.join("\n")
    end
  end
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

# @return [Bool] Whether the Rakefile in the current working directory has a
#         task with the given name.
#
def rake_task?(task)
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
  puts '-' * 80
  puts cyan(string)
  puts '-' * 80
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
