require 'bundler'

module Bundler
  class Dependency
    attr_reader :rainforest_options
    alias :old_initialize :initialize
    def initialize(name, version, options = {}, &blk)
      @rainforest_options = options
      old_initialize(name, version, options, &blk)
    end

    def rainforest_options
      @rainforest_options.select do |k, v|
        %w(group groups path name require platform platforms type).include?(k)
      end
    end
  end
end

module GemfileCleaner
  def self.in_released_bundle(&block)
    subtitle "Cleaning bundle"
    gemfile, lockfile = Pathname('Gemfile'), Pathname('Gemfile.lock')
    gemfile_contents, lockfile_contents = gemfile.read, lockfile.read
    lockfile.delete
    definition = Bundler.definition
    definition.dependencies.each do |d|
      d.source = nil if d.source && !d.source.is_a?(Bundler::Source::Rubygems)
    end
    Bundler::Installer.install(Bundler.root, definition, {})
    File.open(gemfile, 'w') { |f| f << definition_to_gemfile(definition) }
    block.call
  ensure
    subtitle "Restoring bundle"
    File.open(gemfile, 'w') { |f| f << gemfile_contents }
    File.open(lockfile, 'w') { |f| f << lockfile_contents }
  end

  def self.definition_to_gemfile(definition)
    gemfile = String.new
    gemfile << 'ruby ' << r.to_s << "\n\n" if r = definition.ruby_version

    gemfile << <<-G
def only_valid_keys(opts)
  opts.select { |k, v| v && valid_keys.include?(k) }
end

    G
    definition.dependencies.each do |d|
      gemfile << 'gem "' << d.name << '", "' << d.requirements_list.join('", "') << '"'
      gemfile << ', ' << d.rainforest_options.inspect
      gemfile << "\n"
    end
    gemfile
  end
end
