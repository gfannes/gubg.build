begin
    require(File.join(ENV['gubg'], 'shared.rb'))
rescue LoadError
    puts("Bootstrapping \"shared.rb\"")
    require('./shared.rb')
    GUBG::publish('./', 'shared.rb')
end
include GUBG

task :default => :help
task :help do
    puts('declare: copy all scripts and headers to GUBG::shared')
    puts('define: build and copy libraries and executables to GUBG::shared')
end

task :clean do
    Rake::Task['test:clean'].invoke
end

task :declare do
    publish('./', 'shared.rb')
    publish('src', '**/*.rb', dst: 'ruby')
end

task :define => :declare do
end

task :test do
    Rake::Task['test:build'].invoke
    Rake::Task['test:test'].invoke
end

namespace :test do
    exe = nil
    task :setup do
        require('gubg/build/Executable.rb')
        exe = Build::Executable.new('test.exe')
        exe.set_object_dir('.objects')
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
