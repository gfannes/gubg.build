require('gubg/build/GCC.rb')
require('gubg/build/MSVC.rb')
require('gubg/build/FilePool.rb')
require('gubg/build/IncludeParser.rb')
require('set')

module Build
    class Executable
        include Rake::DSL
        @@re_cpp = /\.cpp$/
        @@re_hpp = /\.(hpp|h)$/
        @@re_sep = /[\.\\\/]/
        @@ext_obj = '.obj'
        def initialize(exe_fn, na = {compiler: nil})
            @exe_fn = exe_fn
            @filenames_per_type = Hash.new{|h,k|h[k] = []}
            compiler_type = case na[:compiler]
                            when NilClass, :gcc then GCC
                            when :msvc then MSVC
                            else na[:compiler] end
            @compiler = compiler_type.new
            @object_dir = Dir.pwd
        end

        def exe_filename()
            @exe_fn
        end

        def set_object_dir(dir)
            @object_dir = dir
            mkdir_p(@object_dir) unless File.exist?(@object_dir)
        end

        def add_sources(sources)
            expand_(sources).each do |fn|
                #puts("Adding #{fn}")
                case fn
                when @@re_cpp then @filenames_per_type[:cpp] << fn
                when @@re_hpp then @filenames_per_type[:hpp] << fn
                else puts("WARNING: unknown filetype for #{fn}")
                end
            end
        end
        def add_include_path(*paths)
            [paths].flatten.each do |path|
                @compiler.add_include_path(path)
            end
        end
        def add_defines(defines)
            [defines].flatten.each do |define|
                @compiler.add_define(define)
            end
        end
        def add_force_include(*fns)
            [fns].flatten.each do |fn|
                @compiler.add_force_include(fn)
            end
        end
        def add_library_path(*paths)
            [paths].flatten.each do |path|
                @compiler.add_library_path(path)
            end
        end
        def add_library(*libs)
            [libs].flatten.each do |lib|
                @compiler.add_library(lib)
            end
        end
        def add_option(*options)
            [options].flatten.each do |option|
                @compiler.add_option(option)
            end
        end

        def create_rules
            return if @rules_are_created

            pool = FilePool.new
            source_fns_.each{|fn|pool.register(fn)}
            header_fns_.each{|fn|pool.register(fn)}

            include_parser = IncludeParser.new

            source_fns_.each do |source|
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
                            pool.find_files(include_part).each do |include_fn|
                                dependencies_staging << include_fn 
                            end
                        end
                    end
                end

                object = object_fn_(source)
                file object => dependencies.to_a do
                    sh @compiler.compile_command(object, source)
                end
            end
            object_fns = object_fns_
            file @exe_fn => object_fns do
                sh @compiler.link_command(@exe_fn, object_fns)
            end
            namespace namespace_name_ do
                task :link => @exe_fn
                task :clean do
                    clean
                end
                task :run do
                    run
                end
            end
            @rules_are_created = true
        end

        #Performs the operations immediately
        def clean
            object_fns_().each{|fn|rm_f(fn)}
            rm_f(@exe_fn)
        end
        def build
            create_rules
            Rake::Task[@exe_fn].invoke()
        end
        def run
            build
            sh "./#{@exe_fn}"
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
        def namespace_name_(t = nil)
            name = "gubg_build_executable_#{@exe_fn}"
            name += ":#{t}" if t
            name
        end
        def source_fns_
            @filenames_per_type[:cpp]
        end
        def header_fns_
            @filenames_per_type[:hpp]
        end
        def object_fn_(source)
            File.join(@object_dir, source.gsub(@@re_sep, '_')+@@ext_obj)
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
