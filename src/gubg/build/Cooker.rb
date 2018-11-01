module GUBG
    module Build
        class Cooker
            def initialize()
                @options = []
                @output_dir = nil
                @recipes = []
            end

            def option(key, value=nil)
                @options << {key: key, value: value}
                self
            end
            def output(dir)
                @output_dir = dir
                self
            end
            def recipe(rcp)
                @recipes << rcp
                self
            end

            def generate(generator, *recipes)
                recipes.each{|rcp|recipe(rcp)}

                cmd = "cook -g #{generator}"
                tmpdir = [".cook"]
                @options.each do |opt|
                    ary = [:key, :value].map{|sym|opt[sym]}.compact
                    cmd << " -T #{ary*"="}"
                    tmpdir += ary
                end
                cmd << " -O #{tmpdir*"/"}"
                cmd << " -o #{@output_dir}" if @output_dir
                @recipes.each{|rcp|cmd << " #{rcp}"}
                Rake::sh cmd
                self
            end
            def ninja(j = nil)
                v_str = " -v"
                j_str = (j ? " -j #{j}" : "")
                Rake::sh "ninja#{v_str}#{j_str}"
                self
            end
            def run(args = nil)
                @recipes.each do |rcp|
                    exe_fn = rcp.gsub(/^\//, "").gsub("/", ".")
                    exe_fn = "./#{exe_fn}" unless GUBG::os == :windows
                    puts exe_fn
                    Rake::sh "#{exe_fn} #{args}"
                end
                self
            end
        end
    end
end
