require 'pathname'
require 'optparse'
require 'yaml'
require 'fileutils'
require 'active_support/core_ext'

module Packagit

  class Executable

    RELEASES_DIR = 'pkg'

    def initialize(argv)
      pwd = Pathname.new(Dir.pwd)
      @config = pwd.join(".packagit")
      version = "undefined"
      if @config.exist?
        if @specification = Packagit::Specification.load(@config)
          version = @specification.version
        end
      end
      @options = {
        checksums: true,
        releases: pwd.join(RELEASES_DIR, version),
        packagers: pwd.join("packagers"),
        tmp: pwd.join("tmp", "packagit")
      }
      optparse = OptionParser.new do |opts|
        opts.banner = "Usage: packagit [options]"
        opts.on('-s', '--[no-]checksums', "Compute check sums (default: #{@options[:checksums]})") do |cs|
          @options[:checksums] = cs
        end
        opts.on('-b', '--builds BUILD[,...]', 'Select builds') do |builds|
          @options[:builds] ||= []
          @options[:builds] += builds.split(/[\,[[:space:]]]+/)
        end
        opts.on('-p', '--packagers PATH', "Define packagers directory (default: #{@options[:packagers]})") do |path|
          @options[:packagers] = Pathname.new(File.expand_path(path))
        end
        opts.on('-r', '--releases PATH', "Define releases directory  (default: #{@options[:releases]})") do |path|
          @options[:releases] = Pathname.new(File.expand_path(path))
        end
        opts.on('-t', '--tmp PATH', "Define temporary directory (default: #{@options[:tmp]})") do |path|
          @options[:tmp] = Pathname.new(path).expand_path
        end
        opts.on('-h', '--help', 'Display this screen') do
          puts opts
          exit
        end
      end
      optparse.parse!

      unless @specification
        puts "Need a config file (.packagit)"
        exit(1)
      end

      unless @builds = @options.delete(:builds)
        @builds ||= []
        if @options[:packagers].exist?
          Dir.chdir(@options[:packagers]) do
            @builds += Dir.glob("*")
          end
        end
      end
      @builds.sort!
    end

    def invoke!
      exit(0) if @builds.empty?

      FileUtils.rm_rf(@options[:tmp])

      # Prepare a clean export of the files
      reference = @options[:tmp].join("reference")
      FileUtils.mkdir_p(reference)

      for file in @specification.files
        source = Pathname.new(file).expand_path
        dest = reference.join(file)
        FileUtils.mkdir_p(dest.dirname)
        FileUtils.cp(source, dest) unless source.directory?
      end

      FileUtils.rm_rf(@options[:releases])
      
      # Launch builds
      STDOUT.sync = true
      now = Time.now
      builds_dir = @options[:tmp].join("builds") 
      for build in @builds
        print "Build #{build}... "
        build_dir = builds_dir.join(build)
        FileUtils.mkdir_p(build_dir.dirname)
        FileUtils.cp_r(reference, build_dir)
        script = @options[:packagers].join(build).join("build")
        release = @options[:releases].join(build)
        FileUtils.mkdir_p(release)
        command   = "BUILD_APP=#{@specification.name}"
        command << " BUILD_VERSION=#{@specification.version}"
        command << " BUILD_DIR=#{build_dir}"
        command << " BUILD_TYPE=#{build}"
        command << " BUILD_LOG=#{builds_dir.join(build + '.log')}"
        command << " BUILD_RELEASE=#{release}"
        command << " #{script} > source.log"
        if script.exist?
          puts command
          `#{command}`
        else
          puts "No script! (#{command})"
        end
        unless release.exist?
          File.write(@options[:releases].join(build, ".placeholder"), "#{@specification.name} #{@specification.version} #{build}")
        end
      end

      if @options[:checksums]
        Dir.chdir(@options[:releases]) do
          files = `find . -type f`.split(/\s+/)
          for algo in %w(sha256 sha1 md5)
            command = "#{algo}sum #{files.join(' ')} > " + @options[:releases].join("#{algo.upcase}SUMS").to_s
            puts command
            system(command)
          end
        end
      end
      
    end

  end

end
