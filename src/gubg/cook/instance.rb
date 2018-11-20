require('gubg/cook/naft')
require('gubg/build')

module GUBG
    module Cook
        class Instance
            GUBG_TOOLCHAIN_PATH = File.join(GUBG::Build.root_dir(), "gubg.build", "src", "gubg", "toolchain")

            attr_reader :build_dir, :toolchains

            def initialize(na = {})
                @build_dir = File.join(GUBG::Build.root_dir, "build", options())
                @cook_executable = "cook"
                @additional_recipes = []

                @toolchains = []
                toolchains = ["default", "gubg.chai"] + (na[:toolchains] || [])
                toolchains.each do |t|
                    if File.exists?(t)
                        @toolchains << t
                    elsif File.exists?(File.join(GUBG_TOOLCHAIN_PATH, t))
                        @toolchains << File.join(GUBG_TOOLCHAIN_PATH, t)
                    else
                        @toolchains << t
                    end
                end

                @toolchains.uniq
                
                @naft = nil
            end

            def naft()
                unless @naft
                    Rake.sh(*cmd("-g", "naft"))
                    fn = File.join(build_dir, "recipes.naft")
                    @naft = Naft.new(fn)
                end
                @naft
            end

            def expand(uri_or_globs)
                uri_or_globs = "**" if !uri_or_globs
                exprs = [uri_or_globs].flatten.compact
                uris = []
                exprs.each do  |u| 
                    res = naft.match(u) 
                    raise "No recipe matching expression #{u}}" if res.empty?
                    uris += res
                end
                uris
            end

            def build(uri_or_globs)
                uris = expand(uri_or_globs)

                # make ninja
                Rake.sh(*cmd("-g", "ninja", *uris))

                # run the ninja
                ninja_fn = File.join(build_dir, "build.ninja")
                Rake.sh("ninja -f #{ninja_fn} -j 8")

                result = {}
                uris.each do |uri|
                    recipe = naft.recipe(uri)
                    fn = recipe.target[:filename] || ""
                    fn = File.join(build_dir, fn) unless fn.empty?
                    result[uri] = fn
                end

                result
            end

            def cmd(*args)

                res = []
                res << @cook_executable
                rcps = [GUBG::Build::root_dir("recipes.chai")] + @additional_recipes
                rcps.each { |r| res << "-f" << r }
                @toolchains.each { |fn| res << "-t" << fn }
                res << "-o" << build_dir()
                res += args
                res
            end

            def options()
                return ""
            end

        end
    end
end
