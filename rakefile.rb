begin
    require(File.join(ENV['gubg'], 'ruby/gubg/shared.rb'))
rescue LoadError
    puts("No published `gubg/shared.rb` found, loading local one.")
    require('./src/gubg/shared.rb')
    GUBG::publish("src", pattern: "gubg/shared.rb", dst: "ruby")
end

task :default do
    sh "rake -T"
end

desc "Install all scripts"
task :prepare  do
    GUBG::publish('src', pattern: '**/*.rb', dst: 'ruby')
    dir = GUBG::mkdir("generated/ninja")
    case GUBG::os
    when :windows
    	sh "unzip extern/ninja-v1.8.2-win.zip -d #{dir}"
    	GUBG::publish(dir, pattern: "*.exe", dst: "bin")
    end
end

task :run
