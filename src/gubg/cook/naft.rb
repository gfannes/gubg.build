require 'gubg/cook/recipe'

require 'gubg/naft/Parser'

module Gubg
    module Cook
        class Naft
            attr_reader :recipes
            def initialize(naft_fn)
                @recipes = {}

                attributes = {}
                stack = []
                recipe = nil

                p = Gubg::Naft::Parser.new(
                    node: ->(tag) { 
                        stack.push(tag)
                        attributes = {}
                    },
                    attr_done: ->() {
                        case stack.last
                        when "recipe"
                            attributes[:type] = (attributes[:type] || :Undefined).to_sym
                            recipe = Gubg::Cook::Recipe.new(attributes[:uri], attributes)
                        when "target"
                            attributes[:type] = (attributes[:type] || :Undefined).to_sym
                            recipe.target = attributes
                        when "file"
                            [:Type, :Language, :Propagation, :OverWrite, :content].each do |s|
                                attributes[s] = (attributes[s] || :Undefined).to_sym
                            end
                            recipe.ingredients << attributes
                        when "key_value"
                            [:Type, :Language, :Propagation, :OverWrite, :content].each do |s|
                                attributes[s] = (attributes[s] || :Undefined).to_sym
                            end
                            recipe.ingredients << attributes
                        when "dependency"
                            recipe.dependencies << attributes[:uri]
                        end
                    },
                    attr: ->(key,value) {
                        attributes[key.to_sym] = value
                    },
                    node_done: ->() {
                        if stack.last == "recipe"
                            recipes[recipe.uri] = recipe
                            recipe = nil
                        end
                        stack.pop
                    }
                )
                p.process(File.read(naft_fn))

            end

            def has_recipe(uri)
                return recipes.has_key?(sl_(uri))
            end

            def recipe(uri)
                return recipes[sl_(uri)]
            end

            def match(uri_or_glob)
                uri_or_glob = sl_(uri_or_glob)
                return @recipes.keys.select { |k| File.fnmatch?(uri_or_glob, k) }
            end

            private
            def sl_(str)
                str = "/" + str if !str.empty? && str[0] != "/"
                str
            end
        end
    end
end
