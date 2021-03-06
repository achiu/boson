require File.join(File.dirname(__FILE__), 'test_helper')

module Boson
  class OptionParserTest < Test::Unit::TestCase
  include OptionTestHelper

  context "IndifferentAccessHash" do
    before(:each) {
      @hash = IndifferentAccessHash.new 'foo' => 'bar', 'baz' => 'bee'
    }
    it "can access values indifferently" do
      @hash['foo'].should == 'bar'
      @hash[:foo].should  == 'bar'
      @hash.values_at(:foo, :baz).should == ['bar', 'bee']
    end

    it "can be initialized with either strings or symbols and be equal" do
      hash2 = IndifferentAccessHash.new :foo=>'bar', :baz=>'bee'
      @hash.should == hash2
    end

    it "returns keys as symbols by default" do
      @hash.should == {:foo=>'bar', :baz=>'bee'}
    end

    it "can set values indifferently" do
      @hash['foo'] = 'duh'
      @hash[:foo].should == 'duh'
      @hash[:baz] = 'wasp'
      @hash['baz'].should == 'wasp'
    end
  end

  context "naming" do
    it "automatically aliases long options with their first letter" do
      create "--foo" => true
      parse("-f")["foo"].should == true
    end

    it "automatically aliases two options with same first letters by aliasing alphabetical first with lowercase and second with uppercase" do
      create :verbose=>:boolean, :vertical=>:string, :verz=>:boolean
      parse('-v', '-V','2').should == {:verbose=>true, :vertical=>'2'}
    end
    
    it "doesn't auto-alias options that have multiple names given" do
      create ["--foo", "--bar"] => :boolean
      parse("-f")["foo"].should == nil
    end

    it "allows aliases to be symbols or strings" do
      create [:foo, :bar, 'baz'] =>:string
      parse("--foo", "12")[:foo].should == "12"
      parse("--bar", "12")[:foo].should == "12"
      parse("--baz", "12")[:foo].should == "12"
    end
    
    it "allows multiple aliases for a given opt" do
      create ["--foo", "--bar", "--baz"] => :string
      parse("--foo", "12")["foo"].should == "12"
      parse("--bar", "12")["foo"].should == "12"
      parse("--baz", "12")["foo"].should == "12"
    end
    
    it "allows custom short names" do
      create "-f" => :string
      parse("-f", "12").should == {:f => "12"}
    end

    it "allows capital short names" do
      create :A => :boolean
      parse("-A")[:A].should == true
    end

    it "allows capital short aliases" do
      create [:awesome, :A] => :string
      parse("--awesome", "bar")[:awesome].should == 'bar'
      parse("-A", "bar")[:awesome].should == 'bar'
    end

    it "allows custom short aliases" do
      create ["--bar", "-f"] => :string
      parse("-f", "12").should == {:bar => "12"}
    end
    
    it "allows humanized opt name" do
      create 'foo' => :string, :bar => :string
      parse("-f", "1", "-b", "2").should == {:foo => "1", :bar => "2"}
    end

    it "allows humanized symbol opt name" do
      create :foo=>:string
      parse('-f','1').should == {:foo=>'1'}
    end

    it "doesn't allow alias to override another option" do
      create :foo=>:string, [:bar, :foo]=>:boolean
      parse("--foo", "boo")[:foo].should == 'boo'
    end

    it "doesn't recognize long opt format for a opt that is originally short" do
      create 'f' => :string
      parse("-f", "1").should == {:f => "1"}
      parse("--f", "1").should == {}
    end
    
    it "accepts --[no-]opt variant for booleans, setting false for value" do
      create "--foo" => :boolean
      parse("--no-foo")["foo"].should == false
      parse("--no-f")["foo"].should == false
      parse("--foo")["foo"].should == true
    end

    it "accepts --[no-]opt variant for single letter booleans" do
      create :e=>true
      parse("--no-e")[:e].should == false
    end

    it "will prefer 'no-opt' variant over inverting 'opt' if explicitly set" do
      create "--no-foo" => true
      parse("--no-foo")["no-foo"].should == true
    end
    
  end

  context "option values can be set with" do
    it "a opt=<value> assignment" do
      create :foo => :string
      parse("--foo=12")["foo"].should == "12"
      parse("-f=12")["foo"].should == "12"
      parse("--foo=bar=baz")["foo"].should == "bar=baz"
      parse("--foo=sentence with spaces")["foo"].should == "sentence with spaces"
    end
  
    it "a -nXY assignment" do
      create "--num" => :numeric
      parse("-n12")["num"].should == 12
    end
  
    it "conjoined short options" do
      create "--foo" => true, "--bar" => true, "--app" => true
      opts = parse "-fba"
      opts["foo"].should == true
      opts["bar"].should == true
      opts["app"].should == true
    end
  
    it "conjoined short options with argument" do
      create "--foo" => true, "--bar" => true, "--app" => :numeric
      opts = parse "-fba", "12"
      opts["foo"].should == true
      opts["bar"].should == true
      opts["app"].should == 12
    end
  end

  context "parse" do
    it "extracts non-option arguments" do
      create "--foo" => :string, "--bar" => true
      parse("foo", "bar", "--baz", "--foo", "12", "--bar", "-T", "bang").should == {
        :foo => "12", :bar => true
      }
      @opt.leading_non_opts.should == ["foo", "bar", "--baz"]
      @opt.trailing_non_opts.should == ["-T", "bang"]
      @opt.non_opts.should == ["foo", "bar", "--baz", "-T", "bang"]
    end

    it "stopped by --" do
      create :foo=>:boolean, :dude=>:boolean
      parse("foo", "bar", "--", "-f").should == {}
      @opt.leading_non_opts.should == %w{foo bar}
      @opt.trailing_non_opts.should == %w{-- -f}
    end

    context "with parse flag" do
      it ":delete_invalid_opts deletes and warns of invalid options" do
        create(:foo=>:boolean)
        capture_stderr {
          @opt.parse(%w{-f -d ok}, :delete_invalid_opts=>true)
        }.should =~ /Deleted invalid option '-d'/
        @opt.non_opts.should == ['ok']
      end

      it ":delete_invalid_opts deletes until - or --" do
        create(:foo=>:boolean, :bar=>:boolean)
        %w{- --}.each do |stop_char|
          capture_stderr {
            @opt.parse(%w{ok -b -d} << stop_char << '-f', :delete_invalid_opts=>true)
          }.should =~ /'-d'/
          @opt.non_opts.should == %w{ok -d} << stop_char << '-f'
        end
      end

      it ":opts_before_args only allows options before args" do
        create(:foo=>:boolean)
        @opt.parse(%w{ok -f}, :opts_before_args=>true).should == {}
        @opt.parse(%w{-f ok}, :opts_before_args=>true).should == {:foo=>true}
      end
    end

    context "with no arguments" do
      it "and no options returns an empty hash" do
        create({})
        parse.should == {}
      end

      it "and several options returns an empty hash" do
        create "--foo" => :boolean, "--bar" => :string
        parse.should == {}
      end
    end
  end

  context "option hashes" do
    it "make hash keys available as symbols as well" do
      create "--foo" => :string
      parse("--foo", "12")[:foo].should == "12"
    end

    it "don't set nonexistant options" do
      create "--foo" => :boolean
      parse("--foo")["bar"].should == nil
      opts = parse
      opts["foo"].should == nil
    end
  end

  context ":required option attribute" do
    before(:all) {
      create "--foo" => {:type=>:string, :required=>true}, :bar => {:type=>:hash, :required=>true}
    }

    it "raises an error if string option isn't given" do
      assert_error(OptionParser::Error, 'no value.*required.*foo') { parse("--bar", "str:ok") }
    end

    it "raises an error if non-string option isn't given" do
      assert_error(OptionParser::Error, 'no value.*required.*bar') { parse("--foo", "yup") }
    end

    it "raises no error when given arguments" do
      parse("--foo", "yup", "--bar","ok:dude").should == {:foo=>'yup', :bar=>{'ok'=>'dude'}}
    end
  end

  context ":bool_default option attribute" do
    before(:all) {
      create :foo=>{:type=>:string, :bool_default=>'whoop'}, :bar=>{:type=>:array, :bool_default=>'1'},
        :verbose=>:boolean, :yep=>{:type=>:string, :bool_default=>true}
    }

    it "sets default boolean" do
      parse('--foo', '--bar', '1')[:foo].should == 'whoop'
      parse('--foo', 'ok', 'dokay')[:foo].should == 'whoop'
    end

    it "sets options normally" do
      parse('--foo=boo', '--bar=har').should == {:foo=>'boo', :bar=>['har']}
    end

    it "sets default boolean for array" do
      parse("--bar", '--foo', '2')[:bar].should == ['1']
    end

    it "sets default boolean for non-string value" do
      parse('--yep', '--foo=2')[:yep].should == true
    end

    it "default booleans can be joined with boolean options" do
      parse('-fbv').should == {:verbose=>true, :bar=>['1'], :foo=>'whoop'}
    end
  end

  context "option with attributes" do
    it "can get type from :type" do
      create :foo=>{:type=>:numeric}
      parse("-f", '3')[:foo] == 3
    end

    it "can get type and default from :default" do
      create :foo=>{:default=>[]}
      parse("-f", "1")[:foo].should == ['1']
      parse[:foo].should == []
    end

    it "assumes :boolean type if no type found" do
      create :foo=>{:some=>'params'}
      parse('-f')[:foo].should == true
    end
  end
  
  def usage
    @opt.formatted_usage.split(" ").sort
  end

  context "#formatted_usage" do
    it "outputs string args with sample values" do
      create "--repo" => :string, "--branch" => "bugfix", "-n" => 6
      usage.should == %w([--branch=bugfix] [--repo=REPO] [-n=6])
    end
    
    it "outputs numeric args with 'N' as sample value" do
      create "--iter" => :numeric
      usage.should == ["[--iter=N]"]
    end

    it "outputs array args with sample value" do
      create "--libs" => :array
      usage.should == ["[--libs=A,B,C]"]
    end

    it "outputs hash args with sample value" do
      create '--paths' => :hash
      usage.should == ["[--paths=A:B,C:D]"]
    end
  end

  context "user defined option class" do
    before(:all) {
      ::FooBoo = Struct.new(:name)
      module ::Boson::Options::FooBoo
        def create_foo_boo(value)
          ::FooBoo.new(value)
        end
        def validate_foo_boo(value); end
      end
      ::Boson::OptionParser.send :include, ::Boson::Options::FooBoo
      create :a=>:foo_boo, :b=>::FooBoo.new('blah'), :c=>:blah_blah,
        :d=>{:type=>:foo_boo, :type=>::FooBoo.new('bling')}
    }

    test "created from symbol" do
      (obj = parse('-a', 'whoop')[:a]).class.should == ::FooBoo
      obj.name.should == 'whoop'
    end

    test "created from default" do
      (obj = parse[:b]).class.should == ::FooBoo
      obj.name.should == 'blah'
    end

    test "created from type attribute" do
      (obj = parse('-d', 'whoop')[:d]).class.should == ::FooBoo
      obj.name.should == 'whoop'
    end

    test "has its validation called" do
      @opt.expects(:validate_foo_boo)
      parse("-a", 'blah')
    end

    test "has default usage" do
      usage[0].should == "[-a=:foo_boo]"
    end

    test "when nonexistant raises error" do
      assert_error(OptionParser::Error, "invalid.*:blah_blah") { parse("-c", 'ok') }
    end
  end
end
end