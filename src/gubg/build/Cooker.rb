module GUBG
    module Build
        class Cooker
            def initialize()
                @toolchains = []
                @options = []
                @output_dir = nil
                @recipes_fns = []
                @recipes = []
            end

            def toolchain(*str_or_fn)
                [str_or_fn].flatten.each do |str_or_fn|
                    @toolchains << str_or_fn
                end
                self
            end

            def option(key, value=nil)
                @options << {key: key, value: value}
                self
            end

            def output(dir)
                @output_dir = dir
                self
            end
            def output_fn(*parts)
                if @output_dir
                    File.join(@output_dir, *parts)
                else
                    File.join(*parts)
                end
            end

            def recipes_fn(*fn)
                [fn].flatten.each do |fn|
                    @recipes_fns << fn
                end
                self
            end

            def recipe(rcp)
                @recipes << rcp
                self
            end

            def generate(generator, *recipes)
                @build_ninja = nil
                if !recipes.empty?()
                    recipes.each{|rcp|recipe(rcp)}

                    case generator
                    when :ninja then @build_ninja = output_fn("build.ninja")
                    end
                    cmd = "cook -g #{generator}"
                    @toolchains.each do |str_or_fn|
                        cmd << " -t #{str_or_fn}"
                    end
                    tmpdir = [".cook"]
                    @options.each do |opt|
                        ary = [:key, :value].map{|sym|opt[sym]}.compact
                        cmd << " -T #{ary*"="}"
                        tmpdir += ary
                    end
                    cmd << " -O #{tmpdir*"/"}"
                    cmd << " -o #{@output_dir}" if @output_dir
                    @recipes_fns.each do |fn|
                        cmd << " -f #{fn}"
                    end
                    @recipes.each{|rcp|cmd << " #{rcp}"}
                    Rake::sh cmd
                end
                self
            end
            def ninja(j = nil)
                if !@build_ninja
                    puts("Warning: No ninja file was generated, did you call generate()?")
                else
                    f_str = " -f #{@build_ninja}"
                    v_str = " -v"
                    j_str = (j ? " -j #{j}" : "")
                    Rake::sh "ninja#{f_str}#{v_str}#{j_str}"
                end
                self
            end
            def ninja_compdb(output_fp = "compile_commands.json")
                raise("No ninja file was generated, did you call generate()?") unless @build_ninja
                if @build_ninja
                    f_str = " -f #{@build_ninja}"
                    v_str = " -v"
                    Rake::sh "ninja#{f_str}#{v_str} -t compdb > #{output_fp}"
                end
                self
            end
            def exe_fns()
                @recipes.map do |rcp|
                    output_fn(rcp.split('/').select{|e|!e.empty?()}*'.')
                end
            end
            def run(*args)
                @recipes.each do |rcp|
                    exe_fn = output_fn(rcp.gsub(/^\//, "").gsub("/", "."))
                    exe_fn = "./#{exe_fn}" unless GUBG::os == :windows
                    Rake::sh(exe_fn, *[args].flatten.map{|e|e.to_s})
                end
                self
            end
            def debug(*args)
                @recipes.each do |rcp|
                    exe_fn = output_fn(rcp.gsub(/^\//, "").gsub("/", "."))
                    exe_fn = "./#{exe_fn}" unless GUBG::os == :windows
                    Rake::sh("nemiver", exe_fn, *[args].flatten.map{|e|e.to_s})
                end
                self
            end
        end
    end
end
