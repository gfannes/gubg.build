require('gubg/build/Compiler.rb')

module Build
    class GCC < Compiler
        def version()
            return @version_ if @version_
            exe = case @arch
                  when :default then 'gcc'
                  when :uno, :lilypad then 'avr-gcc'
                  else raise("Unknown #{@arch}") end
            re = /(\d+)\.(\d+)\.(\d+)( \d\d\d\d\d\d\d\d)?$/
            output = `#{exe} --version`.split("\n")[0]
            if md = re.match(output)
                @version_ = md[1].to_i*10+md[2].to_i
            else
                raise("Could not parse version from #{output}")
            end
            return @version_
        end
        def add_arch_settings_
            return if @arch_settings_added_
            case @arch
            when :default
            when :uno, :lilypad
                @options << 'flto'
                # @options << 'w'
                # @options << 'x'
                # @options << 'c++'
                # @options << 'E'
                # @options << 'CC'
                # @options << 'Wa,-mmcu=atmega328p'
                # @options << 'Wa,-mmcu=avr5'
                @defines << 'ARDUINO=10610'
                @defines << 'ARDUINO_ARCH_AVR'
                @include_paths << GUBG::shared('extern/Arduino-master/hardware/arduino/avr/cores/arduino')

                variant = nil
                case @arch
                when :uno
                    variant = 'standard'
                    @options << 'mmcu=atmega328p'
                    @defines << 'ARDUINO_AVR_UNO'
                    @defines << 'F_CPU=16000000L'
                when :lilypad
                    variant = 'leonardo'
                    @options << 'mmcu=atmega32u4'
                    @defines << 'ARDUINO_AVR_LILYPAD_USB'
                    @defines << 'F_CPU=8000000L'
                    @defines << 'USB_VID=0x1B4F'
                    @defines << 'USB_PID=0x9208'
                    @defines << '\'USB_MANUFACTURER="Unknown"\''
                    @defines << '\'USB_PRODUCT="LilyPad USB"\''
                    @libraries << 'm'
                    # @libraries << 'stdc++'
                end
                @include_paths << GUBG::shared("extern/Arduino-master/hardware/arduino/avr/variants/#{variant}")
            else
            end
            @arch_settings_added_ = true
        end
        def libname(name)
            "lib#{name}.a"
        end
        def color_cmd()
            (version() >= 49 ? '-fdiagnostics-color' : '')
        end
        def compile_command(object, source, type)
            add_arch_settings_()
            v = version()
            default_std = if (v < 49) then 'c++11'
                          elsif (v <= 53) then 'c++14'
                          else 'c++17' end
            cpp_standard_cmd = "-std=#{@cpp_standard || default_std}"
            compiler_cmd = case @arch
                           when :default
                               {cpp: "g++ #{cpp_standard_cmd} -c", c: "gcc -c"}
                           when :uno, :lilypad
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
                             when :default then "g++ #{color_cmd}"
                             when :uno then "avr-gcc #{color_cmd} -w -Os -flto -fuse-linker-plugin -Wl,--gc-sections -mmcu=atmega328p"
                             when :lilypad then "avr-gcc #{color_cmd} -w -Os -flto -fuse-linker-plugin -Wl,--gc-sections -mmcu=atmega32u4"
                             end
                objects_cmd = case @arch
                              when :default then objects*' '
                              when :uno, :lilypad then (objects+[shared_dir("lib/#{@arch}/libarduino-core.a")])*' '
                              end
                cmds << "#{linker_cmd} #{options_cmd} -o #{fn} #{objects_cmd} #{lib_sp_cli} #{lib_cli}"
                case @arch
                when :uno, :lilypad
                    cmds << "avr-objcopy -O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load --no-change-warnings --change-section-lma .eeprom=0 #{fn} #{fn}.eep"
                    cmds << "avr-objcopy -O ihex -R .eeprom #{fn} #{fn}.hex"
                    avrdude_conf = "-C#{shared('extern/Arduino-master/hardware/tools/avr/etc/avrdude.conf')}"
                    #System-wide config is currently used, there is no conf present in the Arduino-master.zip
                    avrdude_conf = ''
                    cmds << "avrdude #{avrdude_conf} -v -patmega328p -carduino -P/dev/ttyACM0 -b115200 -D -Uflash:w:#{fn}.hex:i"
                end
            when :lib then
                ar_cmd = case @arch
                         when :default then "ar"
                         when :uno, :lilypad then "avr-gcc-ar"
                         end
                cmds << "#{ar_cmd} rcs #{fn} #{objects*' '}"
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
