require('gubg/build/Compiler.rb')

module Build
    class MSVC < Compiler
        def compile_command(object, source, type)
            include_paths_cmd = @include_paths.map{|ip|"-I#{ip}"}*' '
            defines_cmd = @defines.map{|d|"-D#{d}"}*' '
            force_includes_cmd = @force_includes.map{|fi|"/FI#{fi}"}*' '
            options_cmd = @options.map do |o|
                case o
                when 'm32', 'O3', 'pg' then nil
                else "-#{o}" end
            end.compact*' '
            type_cmd = case type
                       when :cpp then ''
                       when :c then '/TC'
                       else raise("Unknown source type #{type}") end
            "cl -c #{source} /Fo#{object} #{type_cmd} #{options_cmd} #{include_paths_cmd} #{defines_cmd} #{force_includes_cmd}"
        end
        def link_commands(type, exe, objects)
            library_paths_cmd = @library_paths.map{|lp|"-libpath:#{lp}"}*' '
            libraries_cmd = @libraries.map{|lib|"#{lib}.lib"}*' '
            ["link /OUT:#{exe} #{objects*' '} #{library_paths_cmd} #{libraries_cmd}"]
        end
    end
end
