module Boson
  class LoaderError < StandardError; end
  class LoadingDependencyError < LoaderError; end
  class MethodConflictError < LoaderError; end
  class InvalidLibraryModuleError < LoaderError; end

  module Loader
    attr_reader :library

    def load
      load_init(@source)
      load_dependencies
      load_source
      detect_additions { initialize_library_module }
      is_valid_library? && transfer_loader(@library)
    end

    def load_dependencies
      @library[:created_dependencies] = @library[:dependencies].map do |e|
        next if Library.loaded?(e)
        Library.load_once(e, :dependency=>true) ||
          raise(LoadingDependencyError, "Can't load dependency #{e}")
      end.compact
    end

    def load_source; end

    def load_init(name)
      @library = set_library(name)
      @name = @library[:name].to_s
    end

    def transfer_loader(hash)
      valid_attributes = [:call_methods, :except, :module, :gems, :commands, :dependencies, :created_dependencies]
      hash.delete_if {|k,v| !valid_attributes.include?(k) }
      set_attributes hash.merge(:loaded=>true)
      set_library_commands
      self
    end

    def set_library(name)
      self.class.default_attributes.merge(:name=>@name).merge!(self.config)
    end

    def reload
      @library[:detect_methods] = true
      detected = detect_additions(:modules=>true) { reload_source }
      if (@library[:new_module] = !detected[:modules].empty?)
        @library[:module] = determine_lib_module(detected[:modules])
        @commands.each {|e| @library[:commands].delete(e) } #td: fix hack
        detect_additions { initialize_library_module }
        Boson.commands.delete_if {|e| e.lib == @name }
        @module = library[:module]
      end
      create_commands(@library[:commands])
      true
    end

    def reload_source
      raise LoaderError, "Reload not implemented"
    end

    def is_valid_library?
      @library.has_key?(:module)
    end

    def detect_additions(options={}, &block)
      options = {:record_detections=>true}.merge!(options)
      detected = Util.detect(options.merge(:detect_methods=>@library[:detect_methods]), &block)
      if options[:record_detections]
        @library[:gems] += detected[:gems] if detected[:gems]
        @library[:commands] += detected[:methods]
      end
      detected
    end

    def initialize_library_module
      lib_module = @library[:module] = Util.constantize(@library[:module]) ||
        raise(InvalidLibraryModuleError, "Module #{@library[:module]} doesn't exist")
      check_for_method_conflicts(lib_module)
      if @library[:object_command]
        create_object_command(lib_module)
      else
        Boson::Libraries.send :include, lib_module
        Boson::Libraries.send :extend_object, Boson.main_object
      end
      @library[:call_methods].each {|m| Boson.main_object.send m }
    end

    def check_for_method_conflicts(lib_module)
      return if @library[:force]
      conflicts = Util.common_instance_methods(lib_module, Boson::Libraries)
      unless conflicts.empty?
        raise MethodConflictError,
          "The following commands conflict with existing commands: #{conflicts.join(', ')}"
      end
    end

    def create_object_command(lib_module)
      Libraries::ObjectCommands.create(@library[:name], lib_module)
      if (lib = Boson.libraries.find_by(:module=>Boson::Libraries::ObjectCommands))
        lib.commands << @library[:name]
        Boson.commands << Command.create(@library[:name], lib.name)
        lib.create_command_aliases
      end
    end
  end
end