module GUBG
    module Catch
        class Color
            def initialize()
                @stack = [:white]
            end
            def push(sym)
                @stack.push(sym)
                color_(@stack.last)
            end
            def pop()
                @stack.pop
                color_(@stack.last)
            end
            def scope(sym, &block)
                print push(sym)
                block.call
                print pop
            end
            private
            def color_(sym = nil)
                sym ||= :grey
                case sym
                when :white then "\033[1;37m"
                when :grey then "\033[0;37m"
                when :green then "\033[0;32m"
                when :red then "\033[0;31m"
                when :blue then "\033[0;34m"
                when :purple then "\033[0;35m"
                when :cyan then "\033[0;36m"

                when :yellow then "\033[1;33m"
                when :lightblue then "\033[1;34m"
                when :lightpurple then "\033[1;35m"
                when :lightcyan then "\033[1;36m"
                end
            end
        end

        class TestCase
            attr(:name)
            def initialize(name, &block)
                @name, @block = name, block
                @level = 0
                @color = Color.new
            end

            def section(name, &block)
                print @color.push(:white)
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
                                @color.scope(:lightblue){puts(indent_+"[section](name:#{name}){")}
                                @level += 1
                                print @color.push(:grey)
                                block.call
                                print @color.pop
                                @level -= 1
                                @color.scope(:lightblue){puts(indent_+"}")}
                                @saw_leaf = true if @state.size > @head
                            end
                        elsif ix > state[:follow_ix]
                            state[:has_sibling] = true
                        end
                    end
                    @path.pop if @path.size > @head+1
                end
                @head -= 1
                print @color.pop
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
                print @color.push(:white)
                @color.scope(:lightpurple){puts "[test_case](name:#{@name}){"}
                @level += 1
                
                @summary = summary
                #Indicates the path that should be followed to the first leaf. has_sibling is extra info
                #that is used later to update the @state
                @state = [{follow_ix: 0, has_sibling: false}]
                loop do
                    @color.scope(:lightcyan){puts(indent_+"[iteration]{")}

                    #Info that reflects where we currently are in the tree
                    @path = [0]
                    @head = 0

                    @saw_leaf = false

                    @level += 1
                    print @color.push(:grey)
                    @block.call
                    print @color.pop
                    @level -= 1

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

                    @color.scope(:lightcyan){puts(indent_+"}")}

                    break if @state.empty?
                end
                @level -= 1
                @color.scope(:lightpurple){puts "}"}
                print @color.pop
            end
            private
            def indent_()
                "  "*@level
            end
            def pf_(expr)
                print @color.push(:white)
                pf = (expr ? :passed : :failed)
                case pf
                when :passed
                    @color.scope(:green){puts(indent_+"[passed]")}
                when :failed
                    @color.scope(:red){puts(indent_+"[FAILED]")}
                end
                @color.pop
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
            color = Color.new
            print color.push(:white)
            print("[summary]")
            [:available_test_cases, :selected_test_cases].each{|sym|print("(#{sym}:#{summary[sym]})")}
            puts("{")
            [:passed, :failed].each do |pf|
                c = {passed: :green, failed: :red}[pf]
                color.scope(c){puts("  [#{pf}](count:#{summary[pf]})") } if summary[pf] > 0
            end
            puts("}")
            print color.pop
        end
    end
end
