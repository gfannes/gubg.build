module GUBG
    module Tree
        class Parser
            def initialize(event_points = {node: nil, attr: nil, attr_done: nil, text: nil, node_done: nil})
                @event_points = {
                    node: event_points[:node] || ->(){},
                    attr: event_points[:attr] || ->(){},
                    attr_done: event_points[:attr_done] || ->(){},
                    text: event_points[:text] || ->(){},
                    node_done: event_points[:node_done] || ->(){},
                }

                @bracket_level = nil
                @fence_depth = 0
                @scope_level = 0
                @data, @key, @value = nil
                @attr_allowed = false

                @text = {
                    name: "text",
                    enter: ->(){
                        @bracket_level = 0
                        @fence_depth = 0
                        @data = ""
                    },
                    exit: ->(){
                        @event_points[:text].call(@data) unless @data.empty?
                    },
                    process: ->(ch){
                        if @fence_depth == 0
                            if ch == "`"
                                @bracket_level += 1
                            else
                                @fence_depth = @bracket_level
                            end
                        else
                            if ch == "`"
                                @bracket_level -= 1
                                @fence_depth = 0 if @bracket_level == 0
                            else
                                @bracket_level = @fence_depth
                            end
                        end

                        if @bracket_level == 0
                            case ch
                            when "["
                                return change_state_(@tag)
                            when "("
                                return change_state_(@attr) if @attr_allowed
                            when "{"
                                return change_state_(@open) if @attr_allowed
                            when "}"
                                return change_state_(@close) if @scope_level > 0
                            end
                        end

                        @data << ch
                    },
                }
                @tag = {
                    name: "tag",
                    enter: ->(){
                        if @attr_allowed
                            @attr_allowed = false
                            @event_points[:attr_done].call()
                            @event_points[:node_done].call()
                        end
                        @bracket_level = 0
                        @data = ""
                    },
                    exit: ->(){
                        @event_points[:node].call(@data)
                        @attr_allowed = true
                    },
                    process: ->(ch){
                        case ch
                        when "]"
                            return change_state_(@text) if @bracket_level == 0
                            @bracket_level -= 1
                        when "["
                            @bracket_level += 1
                        end
                        @data << ch
                    },
                }
                @attr = {
                    name: "attr",
                    enter: ->(){
                        @bracket_level = 0
                        @key, @value = "", nil
                    },
                    exit: ->(){
                        @event_points[:attr].call(@key, @value || "")
                    },
                    process: ->(ch){
                        case ch
                        when ":"
                            @value = "" if !@value
                            return
                        when "("
                            @bracket_level += 1
                        when ")"
                            return change_state_(@text) if @bracket_level == 0
                            @bracket_level -= 1
                        end
                        if @value
                            @value << ch
                        else
                            @key << ch
                        end
                    },
                }
                @open = {
                    name: "open",
                    enter: ->(){
                        @scope_level += 1
                        @attr_allowed = false
                        @event_points[:attr_done].call()
                        change_state_(@text)
                    },
                    exit: ->(){},
                    process: ->(ch){},
                }
                @close = {
                    name: "close",
                    enter: ->(){
                        @scope_level -= 1
                        if @attr_allowed
                            @attr_allowed = false
                            @event_points[:attr_done].call()
                            @event_points[:node_done].call()
                        end
                        @event_points[:node_done].call()
                        change_state_(@text)
                    },
                    exit: ->(){},
                    process: ->(ch){},
                }
                change_state_(@text)
            end

            def process(text)
                text.each_char do |ch|
                    @state[:process].call(ch)
                end
                end_of_document_()
            end

            private
            def end_of_document_()
                change_state_(@text)

                change_state_(@close) while @scope_level > 0

                change_state_(nil)

                if @attr_allowed
                    @attr_allowed = false
                    @event_points[:attr_done].call()
                    @event_points[:node_done].call()
                end
            end

            def change_state_(wanted)
                return if @state == wanted
                @state[:exit].call if @state
                @state = wanted
                @state[:enter].call if @state
            end
        end
    end
end
