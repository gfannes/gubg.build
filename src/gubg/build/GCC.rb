require('gubg/build/Compiler.rb')

module Build
    class GCC < Compiler
        def libname(name)
            "lib#{name}.a"
        end
        def compile_command(object, source, type)
            include_paths_cmd = @include_paths.map{|ip|"-I#{ip}"}*' '
            defines_cmd = @defines.map{|ip|"-D#{ip}"}*' '
            force_includes_cmd = @force_includes.map{|fi|"-include #{fi}"}*' '
            options_cmd = @options.map{|o|"-#{o}"}*' '
            cpp_standard_cmd = "-std=#{@cpp_standard || 'c++14'}"
            case type
            when :cpp
                "g++ -fdiagnostics-color #{cpp_standard_cmd} -c #{source} -o #{object} #{include_paths_cmd} #{defines_cmd} #{force_includes_cmd} #{options_cmd}"
            when :c
                "gcc -fdiagnostics-color -c #{source} -o #{object} #{include_paths_cmd} #{defines_cmd} #{force_includes_cmd} #{options_cmd}"
            else raise("Unknown source type #{type}") end
        end
        def link_command(type, fn, objects)
            options_cmd = @options.map do |o|
                case o
                when 'pg', 'm32' then "-#{o}"
                else nil end
            end.compact*' '
            case type
            when :exe then "g++ -fdiagnostics-color #{options_cmd} -o #{fn} #{objects*' '} #{lib_sp_cli} #{lib_cli}"
            when :lib then "ar rcs #{fn} #{objects*' '}"
            else raise("Unknown link type #{type}") end
        end
        def lib_sp_cli()
            @library_paths.flatten.map{|path|"-L#{path}"}*' '
        end
        def lib_cli()
            @libraries.flatten.map{|lib|"-l#{lib}"}*' '
        end
    end
end
