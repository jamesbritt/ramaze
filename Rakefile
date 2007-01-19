require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/contrib/rubyforgepublisher'
require 'fileutils'
require 'pp'
include FileUtils

$:.unshift File.join(File.dirname(__FILE__), "lib")
require 'ramaze/version'

AUTHOR = "manveru"
EMAIL = "m.fellinger@gmail.com"
DESCRIPTION = "Ramaze tries to be a very simple Webframework without the voodoo"
HOMEPATH = 'http://ramaze.rubyforge.org'
BIN_FILES = %w( ramaze )

BASEDIR = File.dirname(__FILE__)

NAME = "ramaze"
REV = File.read(".svn/entries")[/committed-rev="(d+)"/, 1] rescue nil
VERS = ENV['VERSION'] || (Ramaze::VERSION + (REV ? ".#{REV}" : ""))
CLEAN.include ['**/.*.sw?', '*.gem', '.config', '**/*~', '**/data.db', '**/cache.yaml']
RDOC_OPTS = ['--quiet', '--title', "ramaze documentation",
    "--opname", "index.html",
    "--line-numbers", 
    "--main", "doc/README",
    "--inline-source"]

desc "Packages up ramaze gem."
task :default => [:test]
task :package => [:clean]

spec =
    Gem::Specification.new do |s|
        s.name = NAME
        s.version = VERS
        s.platform = Gem::Platform::RUBY
        s.has_rdoc = true
        s.extra_rdoc_files = ["doc/README", "doc/CHANGELOG"]
        s.rdoc_options += RDOC_OPTS + ['--exclude', '^(test|examples|extras)/']
        s.summary = DESCRIPTION
        s.description = DESCRIPTION
        s.author = AUTHOR
        s.email = EMAIL
        s.homepage = HOMEPATH
        s.executables = BIN_FILES
        s.bindir = "bin"
        s.require_path = "lib"

        #s.add_dependency('activesupport', '>=1.3.1')
        #s.required_ruby_version = '>= 1.8.2'

        s.files = %w(doc/README doc/CHANGELOG Rakefile) +
          Dir.glob("{bin,doc,test,lib,templates,extras,website,script}/**/*") + 
          Dir.glob("ext/**/*.{h,c,rb}") +
          Dir.glob("examples/**/*.rb") +
          Dir.glob("tools/*.rb")
        
        # s.extensions = FileList["ext/**/extconf.rb"].to_a
    end

Rake::GemPackageTask.new(spec) do |p|
    p.need_tar = true
    p.gem_spec = spec
end

task :install do
  name = "#{NAME}-#{VERS}.gem"
  sh %{rake package}
  sh %{sudo gem install pkg/#{name}}
end

task :uninstall => [:clean] do
  sh %{sudo gem uninstall #{NAME}}
end

task :record => ['fix-end-spaces', 'add-copyright'] do
  system("darcs", "record")
  system("rake", "changes")
end

task 'changes-xml' do
  File.open('doc/changes.xml', 'w+') do |f|
    f.print(`darcs changes --xml`)
  end
end

task 'changes-text' do
  File.open('doc/changes.txt', 'w+') do |f|
    f.print(`darcs changes --human-readable`)
  end
end

task :changes => ['changes-xml', 'changes-text'] do
  puts(`darcs changes`.split("\n").first(25))
end

task :changelog => :changes do
  cp 'doc/changes.txt', 'doc/CHANGELOG'
end

task 'add-copyright' do
  puts "adding copyright to files that don't have it currently"
  Dir['{lib,test}/**/*{.rb}'].each do |file|
    lines = File.readlines(file).map{|l| l.chomp}
    copyright = [
      "#          Copyright (c) 2006 Michael Fellinger m.fellinger@gmail.com",
      "# All files in this distribution are subject to the terms of the Ruby license."
    ]
    unless lines.first(2) == copyright
      puts "fixing #{file}"
      File.open(file, 'w+') do |f|
        (copyright + lines).each do |line|
          f.puts(line)
        end
      end
    end
  end
end

task :rcov_dir do
  mkdir_p 'doc/output/tools/rcov/'
end

require 'spec/rake/spectask'
desc "Generate HTML report for failing tests"
Spec::Rake::SpecTask.new(:rcov_summary => :rcov_dir) do |t|
  t.spec_files = FileList['test/tc_adapter.rb']
  t.spec_opts = ["--format", "html"]
  t.out = 'doc/output/tools/rcov/test.html'
  t.fail_on_error = false
end

task :test do
  system("ruby",  File.dirname(__FILE__) + '/lib/test/all_tests.rb')
  sh "rake clean"
end

task :rdoc do
  dirs = %w[ doc/README lib doc ].join(' ')
  sh %{rdoc --op rdoc --all --main doc/README #{dirs}}
end

task :undocumented do
  files = Dir[File.join('lib', '**', '*.rb')]

  files.each do |file|
    puts file
    lines_till_here = []
    lines = File.readlines(file).map{|line| line.chomp}

    lines.each do |line|
      if line =~ /def /
        indent = line =~ /[^\s]/
        e = lines_till_here.reverse.find{|l| l =~ /end/}
        i = lines_till_here.reverse.index(e)
        lines_till_here = lines_till_here[-(i)..-1] if i
        unless lines_till_here.any?{|l| l =~ /^\s*#/}
          puts lines_till_here
          puts line
          puts "#{' ' * indent}..."
          puts e
        end
      lines_till_here.clear
      end
      lines_till_here << line
    end
  end
end

task :todo do
  files = Dir[File.join(BASEDIR, '{lib,test}', '**/*.rb')]

  files.each do |file|
    lastline = todo = comment = long_comment = false

    File.readlines(file).each_with_index do |line, lineno|
      lineno += 1
      comment = line =~ /^\s*?#.*?$/ 
      long_comment = line =~ /^=begin/
      long_comment = line =~ /^=end/
      todo = true if line =~ /TODO/ and (long_comment or comment)
      todo = false if line.gsub('#', '').strip.empty? 
      todo = false unless comment or long_comment
      if todo
        unless lastline and lastline + 1 == lineno
          puts
          puts "vim #{file} +#{lineno}"
        end

        l = line.strip.gsub(/^#\s*/, '')
        print '  ' unless l =~ /^-/
        puts l
        lastline = lineno
      end
    end
  end
end

task 'todolist' do
  list = `rake todo`.split("\n")[2..-1]
  tasks = {}
  current = nil

  list.map do |line|
    if line =~ /TODO/ or line.empty?
    elsif line =~ /^vim/
      current = line.split[1]
      tasks[current] = []
    else
      tasks[current] << line
    end
  end

  lines = tasks.map{ |name, items| [name, items, ''] }.flatten
  lines.pop

  File.open(File.join('doc', 'TODO'), 'w+') do |f|
    f.puts(lines)
  end
end

task :patchsize do
  size = `darcs changes`.split("\n").reject{|l| l =~ /^\s/ or l.empty?}.size
  puts "currently we got #{size} patches"
end

task 'fix-end-spaces' do
  Dir['{lib,test}/**/*.rb'].each do |file|
    lines = File.readlines(file)
    new = lines.dup
    lines.each_with_index do |line, i|
      if line =~ /\s+\n/
        puts "fixing #{file}:#{i + 1}"
        p line
        new[i] = line.rstrip
      end
    end

    unless new == lines
      File.open(file, 'w+') do |f|
        new.each do |line|
          f.puts(line)
        end
      end
    end
  end
end
