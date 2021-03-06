# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{boson}
  s.version = "0.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gabriel Horner"]
  s.date = %q{2010-01-23}
  s.default_executable = %q{boson}
  s.description = %q{A command/task framework similar to rake and thor that opens your ruby universe to the commandline and irb.}
  s.email = %q{gabriel.horner@gmail.com}
  s.executables = ["boson"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
     "README.rdoc"
  ]
  s.files = [
    "LICENSE.txt",
     "README.rdoc",
     "Rakefile",
     "VERSION.yml",
     "bin/boson",
     "lib/boson.rb",
     "lib/boson/command.rb",
     "lib/boson/commands.rb",
     "lib/boson/commands/core.rb",
     "lib/boson/commands/web_core.rb",
     "lib/boson/index.rb",
     "lib/boson/inspector.rb",
     "lib/boson/inspectors/argument_inspector.rb",
     "lib/boson/inspectors/comment_inspector.rb",
     "lib/boson/inspectors/method_inspector.rb",
     "lib/boson/libraries/file_library.rb",
     "lib/boson/libraries/gem_library.rb",
     "lib/boson/libraries/local_file_library.rb",
     "lib/boson/libraries/module_library.rb",
     "lib/boson/libraries/require_library.rb",
     "lib/boson/library.rb",
     "lib/boson/loader.rb",
     "lib/boson/manager.rb",
     "lib/boson/namespace.rb",
     "lib/boson/option_command.rb",
     "lib/boson/option_parser.rb",
     "lib/boson/options.rb",
     "lib/boson/pipe.rb",
     "lib/boson/repo.rb",
     "lib/boson/repo_index.rb",
     "lib/boson/runner.rb",
     "lib/boson/runners/bin_runner.rb",
     "lib/boson/runners/console_runner.rb",
     "lib/boson/scientist.rb",
     "lib/boson/util.rb",
     "lib/boson/view.rb",
     "test/argument_inspector_test.rb",
     "test/bin_runner_test.rb",
     "test/comment_inspector_test.rb",
     "test/file_library_test.rb",
     "test/loader_test.rb",
     "test/manager_test.rb",
     "test/method_inspector_test.rb",
     "test/option_parser_test.rb",
     "test/pipe_test.rb",
     "test/repo_index_test.rb",
     "test/repo_test.rb",
     "test/runner_test.rb",
     "test/scientist_test.rb",
     "test/test_helper.rb"
  ]
  s.homepage = %q{http://tagaholic.me/boson/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{tagaholic}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Boson provides users with the power to turn any ruby method into a full-fledged commandline tool. Boson achieves this with powerful options (borrowed from thor) and views (thanks to hirb). Some other unique features that differentiate it from rake and thor include being accessible from irb and the commandline, being able to write boson commands in non-dsl ruby and toggling a pretty view of a command's output without additional view code.}
  s.test_files = [
    "test/argument_inspector_test.rb",
     "test/bin_runner_test.rb",
     "test/comment_inspector_test.rb",
     "test/file_library_test.rb",
     "test/loader_test.rb",
     "test/manager_test.rb",
     "test/method_inspector_test.rb",
     "test/option_parser_test.rb",
     "test/pipe_test.rb",
     "test/repo_index_test.rb",
     "test/repo_test.rb",
     "test/runner_test.rb",
     "test/scientist_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hirb>, [">= 0.2.8"])
      s.add_runtime_dependency(%q<alias>, [">= 0.2.1"])
    else
      s.add_dependency(%q<hirb>, [">= 0.2.8"])
      s.add_dependency(%q<alias>, [">= 0.2.1"])
    end
  else
    s.add_dependency(%q<hirb>, [">= 0.2.8"])
    s.add_dependency(%q<alias>, [">= 0.2.1"])
  end
end

