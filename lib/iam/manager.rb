module Iam
  class Manager
    extend Config
    class<<self
      def create_libraries(libraries, options={})
        libraries.each {|e|
          create_or_update_library(e, options)
        }
      end

      def create_config_libraries
        library_names = Iam.libraries.map {|e| e[:name]}
        config[:libraries].each do |name, lib|
          unless library_names.include?(name)
            Iam.libraries << create_library(name)
          end
        end
      end

      def create_lib_aliases(commands, lib_module)
        aliases_hash = {}
        select_commands = Iam.commands.select {|e| commands.include?(e[:name])}
        select_commands.each do |e|
          if e[:alias]
            aliases_hash[lib_module.to_s] ||= {}
            aliases_hash[lib_module.to_s][e[:name]] = e[:alias]
          end
        end
        Alias.manager.create_aliases(:instance_method, aliases_hash)
      end

      def create_or_update_library(*args)
        if (lib = load_library(*args)) && lib.is_a?(Library)
          puts "Loaded library #{lib[:name]}"
        end
      end

      def load_library(library, options={})
        lib = Library.load_and_create(library, options)
        if (existing_lib = Iam.libraries.find {|e| e[:name] == lib[:name]})
          existing_lib.merge!(lib)
        else
          Iam.libraries << lib
        end

        add_lib_commands(lib)
        lib
      end

      def add_lib_commands(lib)
        if lib[:loaded]
          lib[:commands].each {|e| Iam.commands << create_command(e, lib[:name])}
          if lib[:commands].size > 0
            if lib[:module]
              create_lib_aliases(lib[:commands], lib[:module])
            else
              if (commands = Iam.commands.select {|e| lib[:commands].include?(e[:name])}) && commands.find {|e| e[:alias]}
                puts "No aliases created for lib #{lib[:name]} because there is no lib module"
              end
            end
          end
        end
      end

      def create_library(*args)
        lib = Library.create(*args)
        add_lib_commands(lib)
        lib
      end

      def create_command(name, library=nil)
        (config[:commands][name] || {}).merge({:name=>name, :lib=>library.to_s})
      end
    end
  end
end
