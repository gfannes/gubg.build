require('gubg/build/GCC.rb')
require('gubg/build/MSVC.rb')
require('gubg/build/FilePool.rb')
require('gubg/build/IncludeParser.rb')
require('set')
require('fileutils')

module Build
    class Library
        include Rake::DSL
        @@re_cpp = /\.cpp$/
        @@re_hpp = /\.(hpp|h)$/
        @@re_c = /\.c$/
        @@re_sep = /[\.\\\/]/
        @@ext_obj = '.obj'
        def initialize(lib_fn, na = {compiler: nil, arch: nil})
            @arch = na[:arch] || :default
            @filenames_per_type = Hash.new{|h,k|h[k] = []}
            compiler_type = case na[:compiler]
                            when NilClass, :gcc then GCC
                            when :msvc then MSVC
                            else na[:compiler] end
            @compiler = compiler_type.new(@arch)
            @lib_fn = @compiler.libname(lib_fn)
            set_cache_dir('.cache')
        end

        def lib_filename()
            @lib_fn
        end

        def set_cache_dir(dir)
            @cache_dir = dir
            mkdir_p(@cache_dir) unless File.exist?(@cache_dir)
        end

        def add_sources(sources)
            expand_(sources).each do |fn|
                #puts("Adding #{fn}")
                case fn
                when @@re_cpp then @filenames_per_type[:cpp] << fn
                when @@re_hpp then @filenames_per_type[:hpp] << fn
                when @@re_c then @filenames_per_type[:c] << fn
                else puts("WARNING: unknown filetype for #{fn}")
                end
            end
        end
        def add_include_path(*paths)
            [paths].flatten.each do |path|
                @compiler.add_include_path(path)
            end
        end
        def add_define(defines)
            [defines].flatten.each do |define|
                @compiler.add_define(define)
            end
        end
        def add_force_include(*fns)
            [fns].flatten.each do |fn|
                @compiler.add_force_include(fn)
            end
        end
        def add_option(*options)
            [options].flatten.each do |option|
                @compiler.add_option(option)
            end
        end

        def create_rules
            return if @rules_are_created

            do_log = false

            pool = FilePool.new
            source_fns_.each{|fn|pool.register(fn)}
            header_fns_.each{|fn|pool.register(fn)}

            include_parser = IncludeParser.new

            source_infos_.each do |info|
                source = info[:fn]
                type = info[:type]
                #puts("Adding compile rule for #{source}")

                #Determine the dependencies for source
                dependencies = Set.new
                dependencies_staging = [source]
                while !dependencies_staging.empty?
                    fn = dependencies_staging.shift
                    #Only extract the includes and do further dependency checking if this file is not yet in the dependencies set
                    if dependencies.add?(fn)
                        includes = include_parser.extract_includes(fn)
                        includes.each do |include_part|
                            puts("Looking for #{include_part} in the file pool") if do_log
                            pool.find_files(include_part).each do |include_fn|
                                puts("    Found: #{include_fn}") if do_log
                                dependencies_staging << include_fn 
                            end
                        end
                    end
                end

                object = object_fn_(source)

                compile_cmd = @compiler.compile_command(object, source, type)

                #We create an extra dependency file containing things like the actual compilation command
                #to make sure we recompile when the compiler flags change
                settings_fn = create_settings_file_(object+'.settings.txt') do |fo|
                    fo.puts(compile_cmd)
                end
                dependencies.add(settings_fn)

                if do_log
                    puts("Dependencies for #{object}:")
                    dependencies.each{|dep|puts(" => #{dep}")}
                end
                file object => dependencies.to_a do
                    sh compile_cmd
                end
            end

            object_fns = object_fns_
            cached_lib_fn = cache_fn_(@lib_fn)
            link_cmds = @compiler.link_commands(:lib, cached_lib_fn, object_fns)
            #We create an extra dependency file containing things like the actual link command
            #to make sure we relink when the linker flags change
            settings_fn = create_settings_file_(cached_lib_fn+'.settings.txt') do |fo|
                link_cmds.each do |link_cmd|
                    fo.puts(link_cmd)
                end
            end
            file cached_lib_fn => [settings_fn, object_fns].flatten do
                link_cmds.each do |link_cmd|
                    sh link_cmd
                end
            end
            # file @lib_fn => cached_lib_fn do
            #     FileUtils.install(cached_lib_fn, @lib_fn)
            # end
            namespace namespace_name_ do
                task :build => cached_lib_fn do
                    FileUtils.install(cached_lib_fn, @lib_fn)
                end
                # task :link => @lib_fn
                task :link => :build
                task :clean do
                    clean
                end
            end
            @rules_are_created = true
        end

        #Performs the operations immediately
        def clean
            object_fns_().each{|fn|rm_f(fn)}
            rm_f(@lib_fn)
        end
        def build
            create_rules
            # Rake::Task[@lib_fn].invoke()
            Rake::Task[namespace_name_(:build)].invoke()
        end

        #Rulenames to be used as rake rule prerequistite
        def clean_rule
            create_rules
            namespace_name_(:clean)
        end
        def build_rule
            create_rules
            namespace_name_(:link)
        end
        def run_rule
            create_rules
            namespace_name_(:run)
        end

        private
        def create_settings_file_(fn, &block)
            #We work with a tmp settings file, else, the rake file task will always build the object
            #because of the recent timestamp
            tmp_fn = fn+'.tmp'
            raise("Cannot create the temporary settings file \"#{tmp_fn}\", it already exists") if File.exist?(tmp_fn)
            begin
                dir = File.dirname(tmp_fn)
                FileUtils.mkdir_p(dir) unless File.exist?(dir)
                File.open(tmp_fn, 'w') do |fo|
                    yield(fo)
                end
                FileUtils.install(tmp_fn, fn)
            ensure
                FileUtils.rm(tmp_fn) if File.exist?(tmp_fn)
            end
            fn
        end
        def namespace_name_(t = nil)
            name = "gubg_build_library_#{@arch}_#{@lib_fn}"
            name += ":#{t}" if t
            name
        end
        def source_infos_
            ary = []
            [:cpp, :c].each do |type|
                @filenames_per_type[type].each do |fn|
                    ary << {fn: fn, type: type}
                end
            end
            ary
        end
        def source_fns_
            source_infos_.map{|info|info[:fn]}
        end
        def header_fns_
            @filenames_per_type[:hpp]
        end
        def cache_fn_(fn)
            File.join(@cache_dir, @arch.to_s, fn.gsub(@@re_sep, '_'))
        end
        def object_fn_(source)
            cache_fn_(source)+@@ext_obj
        end
        def object_fns_
            source_fns_.map{|fn|object_fn_(fn)}
        end
        def expand_(filenames)
            filenames = [filenames].flatten
            filenames.map! do |el|
                case el
                when FileList then el.to_a
                else el end
            end.flatten
        end
    end
end
