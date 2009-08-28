require File.join(File.dirname(__FILE__), 'test_helper')

module Boson
  class RunnerTest < Test::Unit::TestCase
    context "repl_runner" do
      def activate(*args)
        Hirb.stubs(:enable)
        Boson.activate(*args)
      end

      before(:all) { reset_boson }
      before(:each) { Boson::ReplRunner.instance_eval("@initialized = false") }

      test "loads default irb library when irb exists" do
        eval %[module ::IRB; module ExtendCommandBundle; end; end]
        Library.expects(:load).with {|*args| args[0].include?(IRB::ExtendCommandBundle) }
        activate
        IRB.send :remove_const, "ExtendCommandBundle"
      end

      test "loads default libraries and libraries in :defaults config" do
        defaults = Boson::Runner.boson_libraries + ['yo']
        with_config(:defaults=>['yo']) do
          Library.expects(:load).with {|*args| args[0] == defaults }
          activate
        end
      end

      test "doesn't call init twice" do
        activate
        ReplRunner.expects(:init).never
        activate
      end

      test "loads multiple libraries with :libraries option" do
        ReplRunner.expects(:init)
        Library.expects(:load).with([:lib1,:lib2], anything)
        activate(:libraries=>[:lib1, :lib2])
      end
    end

    context "bin_runner" do
      def start(*args)
        Hirb.stubs(:enable)
        BinRunner.start(args)
      end

      before(:all) { require 'boson/runners/bin_runner' }
      before(:all) { reset_boson }

      test "with no arguments prints usage" do
        capture_stdout { start }.should =~ /^boson/
      end

      test "with undiscovered command prints error" do
         BinRunner.expects(:discover_command).with('blah', anything).returns(false)
        capture_stderr { start('blah') }.should =~ /Error.*blah/
      end

      test "executes basic command" do
        BinRunner.expects(:init).returns(true)
        BinRunner.stubs(:render_output)
        Boson.main_object.expects(:send).with('kick','it')
        start 'kick','it'
      end

      test "executes sub command" do
        obj = Object.new
        Boson.main_object.extend Module.new { def phone; Struct.new(:home).new('done'); end }
        BinRunner.expects(:init).returns(true)
        BinRunner.expects(:render_output).with('done')
        start 'phone.home'
      end
    end
  end
end