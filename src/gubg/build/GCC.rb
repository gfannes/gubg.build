require('gubg/build/Compiler.rb')

module Build
    class GCC < Compiler
        def libname(name)
            "lib#{name}.a"
        end
        def compile_command(object, source, type)
            include_paths_cmd = @include_paths.map{|ip|"-I#{ip}"}*' '
            defines_cmd = @defines.map{|ip|"-D#{ip}"}*' '
            case type
            when :cpp
                "g++ -std=c++11 -c #{source} -o #{object} #{include_paths_cmd} #{defines_cmd}"
            when :c
                "gcc -c #{source} -o #{object} #{include_paths_cmd} #{defines_cmd}"
            else raise("Unknown source type #{type}") end
        end
        def link_command(type, fn, objects)
            case type
            when :exe then "g++ -o #{fn} #{objects*' '} #{lib_sp_cli} #{lib_cli}"
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
