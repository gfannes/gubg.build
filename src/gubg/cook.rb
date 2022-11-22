require "gubg/cook/instance"

module Gubg
    module Cook

        @@instances = nil

        def self.[](key)
            return instances[key]
        end

        def self.[]=(key, value)
            instances[key] = value
        end

        private
        def self.instances()
            unless @@instances
                @@instances  = {}
                @@instances[:debug] = Instance.new()
                @@instances[:release] = Instance.new()
                @@instances[:default] = @@instances[:release]
            end
            @@instances
        end
    end
end
