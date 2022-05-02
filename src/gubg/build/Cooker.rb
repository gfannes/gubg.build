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
                recipes.each{|rcp|recipe(rcp)}

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
                self
            end
            def ninja(j = nil)
                f_str = " -f #{output_fn("build.ninja")}"
                v_str = " -v"
                j_str = (j ? " -j #{j}" : "")
                Rake::sh "ninja#{f_str}#{v_str}#{j_str}"
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
