module GUBG
    module Cook
        class Recipe
        
            attr_accessor :uri, :display_name, :path, :type, :build_target, :dependencies, :ingredients, :target
            def initialize(uri, na = {})
                @uri = uri
                @display_name = na[:display_name] || @uri
                @path = na[:path] || nil
                @type = na[:type] || :Undefined
                @build_target = na[:build_target] || nil
                @ingredients = []
                @dependencies = []
                @target = {}
            end
        end
    end
end
