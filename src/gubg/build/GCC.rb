require('gubg/build/Compiler.rb')

module Build
    class GCC < Compiler
        def GCC.version()
            return @version_ if @version_
            re = /(\d+)\.(\d+)\.(\d+)( \d\d\d\d\d\d\d\d)?$/
            output = `gcc --version`.split("\n")[0]
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
            default_std = (GCC.version >= 49 ? 'c++14' : 'c++11')
            cpp_standard_cmd = "-std=#{@cpp_standard || default_std}"
            compiler_cmd = case @arch
                           when NilClass
                               {cpp: "g++ #{cpp_standard_cmd} -c", c: "gcc -c"}
                           when :uno
                               @options << 'fpermissive'
                               @options << 'fno-exceptions'
                               @options << 'ffunction-sections'
                               @options << 'fdata-sections'
                               @options << 'flto'
                               # @options << 'w'
                               # @options << 'x'
                               # @options << 'c++'
                               # @options << 'E'
                               # @options << 'CC'
                               @options << 'mmcu=atmega328p'
                               # @options << 'Wa,-mmcu=atmega328p'
                               # @options << 'Wa,-mmcu=avr5'
                               @defines << 'F_CPU=16000000L'
                               @defines << 'ARDUINO=10610'
                               @defines << 'ARDUINO_AVR_UNO'
                               @defines << 'ARDUINO_ARCH_AVR'
                               @include_paths << GUBG::shared('extern/Arduino-master/hardware/arduino/avr/cores/arduino')
                               @include_paths << GUBG::shared('extern/Arduino-master/hardware/arduino/avr/variants/standard')
                               {cpp: "avr-g++ -c -g -Os -w #{cpp_standard_cmd}", c: "avr-gcc"}
                           else
                               raise("Unknown arch #{@arch}")
                           end
            include_paths_cmd = @include_paths.map{|ip|"-I#{ip}"}*' '
            defines_cmd = @defines.map{|ip|"-D#{ip}"}*' '
            force_includes_cmd = @force_includes.map{|fi|"-include #{fi}"}*' '
            options_cmd = @options.map{|o|"-#{o}"}*' '
            "#{compiler_cmd[type]} #{color_cmd} #{options_cmd} #{source} -o #{object} #{include_paths_cmd} #{defines_cmd} #{force_includes_cmd}"
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
