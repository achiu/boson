require File.join(File.dirname(__FILE__), 'test_helper')

module Boson
  class IndexTest < Test::Unit::TestCase
    # since we're defining our own @commands, @libraries, @lib_hashes
    before(:all) { Index.instance_variable_set "@read", true }

    context "read_and_transfer" do
      before(:each) { reset_boson; Index.instance_eval "@libraries = @commands = nil" }

      def transfers(options={})
        Index.instance_variable_set "@libraries", [Library.new(:name=>'blah'), Library.new(:name=>'bling')]
        Index.instance_variable_set "@commands", [Command.new(:name=>'blurb', :lib=>'blah')]
        Index.read_and_transfer options[:ignored] || []
        Boson.libraries.map {|e| e.name}.should == options[:libraries]
        Boson.commands.map {|e| e.name}.should == options[:commands]
      end

      test "transfers libraries with no libraries to ignore" do
        transfers :libraries=>%w{blah bling}, :commands=>%w{blurb}, :ignored=>[]
      end

      test "transfers libraries and commands except for ignored libraries and its commands" do
        transfers :libraries=>%w{bling}, :commands=>[], :ignored=>%w{blah}
      end

      test "doesn't replace existing libraries" do
        lib = Library.new(:name=>'blah')
        cmd = Command.new(:name=>'blurb', :lib=>'blah')
        Boson.libraries << lib
        Boson.commands << cmd
        transfers :libraries=>%w{blah bling}, :commands=>%w{blurb}
        Boson.libraries.include?(lib).should == true
        Boson.commands.include?(cmd).should == true
      end
    end

    context "find_library" do
      before(:all) {
        reset_boson
        commands = [Command.new(:name=>'blurb', :lib=>'blah', :alias=>'bb'), 
          Command.new(:name=>'bling', :lib=>'namespace', :alias=>'bl'),
          Command.new(:name=>'sub', :lib=>'bling', :alias=>'s')
        ]
        Index.instance_variable_set "@libraries", [Library.new(:name=>'blah'), Library.new(:name=>'bling')]
        Index.instance_variable_set "@commands", commands
      }

      test "finds command aliased or not" do
        Index.find_library('blurb', nil).should == 'blah'
        Index.find_library('bb', nil).should == 'blah'
      end

      test "doesn't find command" do
        Index.find_library('blah', nil).should == nil
      end

      test "finds a subcommand aliased or not" do
        Index.find_library('bling', 'sub').should == 'bling'
        Index.find_library('bl', 's').should == 'bling'
      end

      test "doesn't find a subcommand" do
        Index.find_library('d', 'd').should == nil
      end
    end

    context "changed_libraries" do
      before(:all) { Index.instance_eval "@lib_hashes = nil" }

      def changed(string, all_libs=['file1'])
        Runner.expects(:all_libraries).returns(all_libs)
        Index.instance_variable_set "@lib_hashes", {"file1"=>Digest::MD5.hexdigest("state1")}
        File.stubs(:exists?).returns(true)
        File.expects(:read).returns(string)
        Index.changed_libraries
      end

      test "detects changed libraries" do
        changed("state2").should == %w{file1}
      end

      test "detects new libraries" do
        changed("state1", ['file2']).should == %w{file2}
      end

      test "detects no changed libraries" do
        changed("state1").should == []
      end
    end
  end
end