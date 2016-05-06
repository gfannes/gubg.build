require('gubg/build/Compiler.rb')

module Build
    class GCC < Compiler
        def GCC.version()
            return @version_ if @version_
            re = /(\d+)\.(\d+)\.(\d+)( \d\d\d\d\d\d\d\d)?$/
            output = `gcc --version`.split('\n')[0]
            if md = re.match(output)
                @version_ = md[1].to_i*10+md[2].to_i
            else
                raise("Could not parse version from #{output}")
            end
            return @version_
        end
        def libname(name)
            "lib#{name}.a"
        end
        def color_cmd()
            (GCC.version >= 49 ? '-fdiagnostics-color' : '')
        end
        def compile_command(object, source, type)
            include_paths_cmd = @include_paths.map{|ip|"-I#{ip}"}*' '
            defines_cmd = @defines.map{|ip|"-D#{ip}"}*' '
            force_includes_cmd = @force_includes.map{|fi|"-include #{fi}"}*' '
            options_cmd = @options.map{|o|"-#{o}"}*' '
            default_std = (GCC.version >= 49 ? 'c++14' : 'c++11')
            cpp_standard_cmd = "-std=#{@cpp_standard || default_std}"
            case type
            when :cpp
                "g++ #{color_cmd} #{cpp_standard_cmd} -c #{source} -o #{object} #{include_paths_cmd} #{defines_cmd} #{force_includes_cmd} #{options_cmd}"
            when :c
                "gcc #{color_cmd} -c #{source} -o #{object} #{include_paths_cmd} #{defines_cmd} #{force_includes_cmd} #{options_cmd}"
            else raise("Unknown source type #{type}") end
        end
        def link_command(type, fn, objects)
            options_cmd = @options.map do |o|
                case o
                when 'pg', 'm32' then "-#{o}"
                else nil end
            end.compact*' '
            case type
            when :exe then "g++ #{color_cmd} #{options_cmd} -o #{fn} #{objects*' '} #{lib_sp_cli} #{lib_cli}"
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
