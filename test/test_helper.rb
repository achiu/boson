require 'rubygems'
require 'test/unit'
require 'context' #gem install jeremymcanally-context --source http://gems.github.com
require 'matchy' #gem install jeremymcanally-matchy --source http://gems.github.com
require 'mocha'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'boson'

class Test::Unit::TestCase
  # make local so it doesn't pick up my real boson dir
  Boson.dir = File.expand_path('.')

  def reset_boson
    (Boson.instance_variables - ['@dir']).each do |e|
      Boson.instance_variable_set(e, nil)
    end
    Boson.send :remove_const, "Commands"
    eval "module ::Boson::Commands; end"
    $".delete('boson/commands/core.rb') && require('boson/commands/core.rb')
    $".delete('boson/commands/namespace.rb') && require('boson/commands/namespace.rb')
    Boson::Runner.instance_eval("@initialized = false")
  end

  def reset_main_object
    Boson.send :remove_const, "Commands"
    eval "module ::Boson::Commands; end"
    Boson.main_object = Object.new
  end

  def reset_libraries
    Boson.instance_eval("@libraries = nil")
  end

  def reset_commands
    Boson.instance_eval("@commands = nil")
  end

  def command_exists?(name, bool=true)
    Boson::Command.loaded?(name).should == bool
  end

  def library_loaded?(name, bool=true)
    Boson::Library.loaded?(name).should == bool
  end

  def library(name)
    Boson.libraries.find_by(:name=>name)
  end

  def library_has_module(lib, lib_module)
    Boson::Library.loaded?(lib).should == true
    test_lib = library(lib)
    (test_lib.module.is_a?(Module) && (test_lib.module.to_s == lib_module)).should == true
  end

  # mocks as a file library
  def mock_library(lib, options={})
    options[:file_string] ||= ''
    File.expects(:exists?).with(Boson::Library.library_file(lib.to_s)).returns(true)
    if options.delete(:no_module_eval)
      Kernel.expects(:load).with { eval options.delete(:file_string); true}.returns(true)
    else
      File.expects(:read).returns(options.delete(:file_string))
    end
  end

  def load(lib, options={})
    mock_library(lib, options) unless options.delete(:no_mock)
    Boson::Library.load([lib], options)
  end

  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end

  def with_config(options)
    old_config = Boson.config
    Boson.config = Boson.config.merge(options)
    yield
    Boson.config = old_config
  end

  def capture_stderr(&block)
    original_stderr = $stderr
    $stderr = fake = StringIO.new
    begin
      yield
    ensure
      $stderr = original_stderr
    end
    fake.string
  end
end
