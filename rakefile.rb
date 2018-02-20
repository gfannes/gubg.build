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
task :prepare do
    GUBG::publish('src', pattern: '**/*.rb', dst: 'ruby')
end

task :run
