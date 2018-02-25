module GUBG
    module Catch
        class TestCase
            attr(:name)
            def initialize(name, &block)
                @name, @block = name, block
            end

            def section(name, &block)
                indent = "  "*@head
                @head += 1
                begin
                    @path << -1 if @path.size <= @head
                    @path[@head] += 1
                    begin
                        ix = @path[@head]
                        @state << {follow_ix: 0, has_sibling: false} if @state.size <= @head
                        state = @state[@head]
                        if ix == state[:follow_ix]
                            if @saw_leaf
                                #We already saw a leaf node and will hence skip all the rest. We do need to check
                                #hereunder if we have a sibling.
                            else
                                puts(indent+"  [section](name:#{name}){")
                                block.call
                                puts(indent+"  }")
                                @saw_leaf = true if @state.size > @head
                            end
                        elsif ix > state[:follow_ix]
                            state[:has_sibling] = true
                        end
                    end
                    @path.pop if @path.size > @head+1
                end
                @head -= 1
            end

            def must(expr)
                pf = pf_(expr)
                @summary[pf] += 1
            end
            def must_eq(actual, wanted)
                pf = pf_(actual == wanted)
                @summary[pf] += 1
            end

            def run(summary)
                puts "[test_case](name:#{@name}){"
                @summary = summary
                #Indicates the path that should be followed to the first leaf. has_sibling is extra info
                #that is used later to update the @state
                @state = [{follow_ix: 0, has_sibling: false}]
                loop do
                    #Info that reflects where we currently are in the tree
                    @path = [0]
                    @head = 0

                    @saw_leaf = false

                    @block.call

                    while !@state.empty?
                        state = @state.last
                        if state[:has_sibling]
                            #Has a sibling, select it the next time
                            state[:follow_ix] += 1
                            state[:has_sibling] = false
                            break
                        else
                            #Has no sibling, remove it
                            @state.pop
                        end
                    end

                    break if @state.empty?
                end
                puts "}"
            end
            private
            def pf_(expr)
                pf = (expr ? :passed : :failed)
                case pf
                when :passed
                    puts("[passed]")
                when :failed
                    puts("[FAILED]")
                end
                pf
            end
        end

        @test_cases = []
        @current_test_case = nil

        def self.test_case(name, &block)
            @test_cases << TestCase.new(name, &block)
        end
        def test_case(name, &block)
            Catch::test_case(name, &block)
        end

        def self.section(name, &block)
            @current_test_case.section(name, &block)
        end
        def section(name, &block)
            Catch::section(name, &block)
        end

        def self.must(expr)
            @current_test_case.must(expr)
        end
        def must(expr)
            Catch::must(expr)
        end
        def self.must_eq(actual, wanted)
            @current_test_case.must_eq(actual, wanted)
        end
        def must_eq(actual, wanted)
            Catch::must_eq(actual, wanted)
        end

        def self.run(filter = nil)
            filter ||= ""
            re = ""
            filter.each_char{|ch|re << ".*#{ch}"}
            re << ".*"
            re = Regexp.new(re)

            summary = Hash.new{|h,k|h[k]=0}
            @test_cases.each do |tc|
                summary[:available_test_cases] += 1
                if re =~ tc.name
                    @current_test_case = tc
                    summary[:selected_test_cases] += 1
                    tc.run(summary)
                end
            end
            puts summary
        end
    end
end
