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
                               {
                                   cpp: "avr-g++ -c -g -Os -w #{cpp_standard_cmd} -fpermissive -fno-exceptions -ffunction-sections -fdata-sections",
                                   c: "avr-gcc -c -g",
                                   asm: "avr-gcc -c -g -x assembler-with-cpp",
                               }
                           else
                               raise("Unknown arch #{@arch}")
                           end
            include_paths_cmd = @include_paths.map{|ip|"-I#{ip}"}*' '
            defines_cmd = @defines.map{|ip|"-D#{ip}"}*' '
            force_includes_cmd = @force_includes.map{|fi|"-include #{fi}"}*' '
            options_cmd = @options.map{|o|"-#{o}"}*' '
            "#{compiler_cmd[type]} #{color_cmd} #{options_cmd} #{source} -o #{object} #{include_paths_cmd} #{defines_cmd} #{force_includes_cmd}"
        end
        def link_commands(type, fn, objects)
            cmds = []

            options_cmd = @options.map do |o|
                case o
                when 'pg', 'm32' then "-#{o}"
                else nil end
            end.compact*' '

            case type
            when :exe then
                linker_cmd = case @arch
                             when NilClass then "g++ #{color_cmd}"
                             when :uno then "avr-gcc #{color_cmd} -w -Os -flto -fuse-linker-plugin -Wl,--gc-sections -mmcu=atmega328p"
                             end
                objects_cmd = case @arch
                              when NilClass then objects*' '
                              when :uno then ([shared_dir('lib/libarduino-core.a')]+objects)*' '
                              end
                cmds << "#{linker_cmd} #{options_cmd} -o #{fn} #{objects_cmd} #{lib_sp_cli} #{lib_cli}"
                case @arch
                when :uno
                    cmds << "avr-objcopy -O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load --no-change-warnings --change-section-lma .eeprom=0 #{fn} #{fn}.eep"
                    cmds << "avr-objcopy -O ihex -R .eeprom #{fn} #{fn}.hex"
                    avrdude_conf = "-C#{shared('extern/Arduino-master/hardware/tools/avr/etc/avrdude.conf')}"
                    #System-wide config is currently used, there is no conf present in the Arduino-master.zip
                    avrdude_conf = ''
                    cmds << "avrdude #{avrdude_conf} -v -patmega328p -carduino -P/dev/ttyACM0 -b115200 -D -Uflash:w:#{fn}.hex:i"
                end
                cmds
            when :lib then
                ar_cmd = case @arch
                             when NilClass then "ar"
                             when :uno then "avr-gcc-ar"
                             end
                "#{ar_cmd} rcs #{fn} #{objects*' '}"
            else raise("Unknown link type #{type}") end

            cmds
        end
        def lib_sp_cli()
            @library_paths.flatten.map{|path|"-L#{path}"}*' '
        end
        def lib_cli()
            @libraries.flatten.map{|lib|"-l#{lib}"}*' '
        end
    end
end
