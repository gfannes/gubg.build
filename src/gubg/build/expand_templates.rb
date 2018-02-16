require("gubg/naft/Parser")

module GUBG
    module Build
        def self.expand_templates(fn)
            items = []
            tags = []
            info = nil
            prefix = nil
            p = Naft::Parser.new(
                node: ->(tag){
                    puts "tag: #{tag}"
                    case tag
                    when "output" then tags << :output
                    end

                    if tags == [:output]
                        info = {}
                    end
                    items << {type: :txt, data: "[#{tag}]"}
                },
                node_done: ->(){
                    puts "tag closed"
                    if tags == [:output]
                        items << {type: :txt, data: "#{prefix}}\n"}
                    end
                    tags.pop
                },
                text: ->(txt){
                    puts "txt: #{txt}"
                    if tags == [:output]
                        #Eat this text
                    else
                        prefix = txt.split("\n").last
                        puts "prefix: #{prefix}"
                        items << {type: :txt, data: txt}
                    end
                },
                attr: ->(key,value){
                    puts "key: #{key}, value: #{value}"
                    if tags == [:output]
                        case key
                        when "script" then info[:script] = value
                        end
                    end
                    items << {type: :txt, data: "(#{key}#{value ? ":" : ""}#{value})"}
                },
                attr_done: ->(){
                    if tags == [:output]
                        items << {type: :txt, data: "{\n"}
                        items << {type: :script, data: info[:script]}
                    end
                },
            )
            p.process(File.read(fn))

            oss = StringIO.new
            items.each do |item|
                case item[:type]
                when :txt then oss.print(item[:data])
                when :script
                    output = StringIO.new
                    eval(item[:data])
                    oss.print(output.string)
                end
            end

            File.write(fn, oss.string)
        end
    end
end

if __FILE__ == $0
    #[output](script:3.times{|i|output.puts("puts #{i}")}){
puts 0
puts 1
puts 2
    #}

    GUBG::Build::expand_templates(__FILE__)
end
