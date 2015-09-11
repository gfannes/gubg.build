$LOAD_PATH << Dir.pwd
require('gubg/build/Executable.rb')

exe = Build::Executable.new('test.exe')
exe.set_object_dir('.objects')
exe.add_sources(FileList.new('test/**/*.*'))
exe.add_include_path('test/inc')

task :clean do
    exe.clean
end
task :build do
    exe.build
end
task :test => :build do
    exe.run
end
