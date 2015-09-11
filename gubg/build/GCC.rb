require('gubg/build/Compiler.rb')

module Build
    class GCC < Compiler
        def compile_command(object, source)
            include_paths_cmd = @include_paths.map{|ip|"-I#{ip}"}*' '
            defines_cmd = @defines.map{|ip|"-D#{ip}"}*' '
            "g++ -std=c++11 -c #{source} -o #{object} #{include_paths_cmd} #{defines_cmd}"
        end
        def link_command(exe, objects)
            "g++ -o #{exe} #{objects*' '}"
        end
    end
end
