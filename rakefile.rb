begin
    require(File.join(ENV['gubg'], 'shared.rb'))
rescue LoadError
    puts("Bootstrapping \"shared.rb\"")
    require('./shared.rb')
    GUBG::publish('shared.rb')
end
include GUBG

task :default do
    sh "rake -T"
end

task :clean do
    Rake::Task['test:clean'].invoke
end

desc "Install all scripts"
task :prepare do
    publish('shared.rb')
    publish('src', pattern: '**/*.rb', dst: 'ruby')
end
task :run

task :test do
    Rake::Task['test:build'].invoke
    Rake::Task['test:test'].invoke
end

namespace :test do
    exe = nil
    task :setup do
        require('gubg/build/Executable.rb')
        exe = Build::Executable.new('test.exe')
        exe.set_cache_dir('.cache')
        exe.add_sources(FileList.new('test/**/*.*'))
        exe.add_include_path('test/inc')
    end
    task :build => :setup do
        exe.build
    end
    task :clean => :setup do
        exe.clean
    end
    task :test => :build do
        exe.run
    end
end
