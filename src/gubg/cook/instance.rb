require('gubg/cook/naft')
require('gubg/build')

module GUBG
    module Cook
        class Instance

            attr_reader :build_dir

            def initialize(na = {})
                @build_dir = File.join(GUBG::Build.root_dir, "build", options())
                @cook_executable = "cook"
                @additional_recipes = []
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

            def build(uri_or_globs)
                exprs = [uri_or_globs].flatten.compact
                uris = exprs.map { |u| naft.match(u) }
                uris = uris.flatten

                # make ninja
                Rake.sh(*cmd("-g", "ninja", *uris))

                # run the ninja
                ninja_fn = File.join(build_dir, "build.ninja")
                Rake.sh("ninja -f #{ninja_fn}")
                
                
            end

            def cmd(*args)
            
                res = []
                res << @cook_executable
                rcps = [GUBG::Build::root_dir("recipes.chai")] + @additional_recipes
                rcps.each { |r| res << "-f" << r }
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
