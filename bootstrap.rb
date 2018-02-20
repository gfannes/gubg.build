#Creates a default gubg environment:
# * $gubg environment vvariable
# * Installs local ruby files
# * Adjusts ruby search path
#
#When using gubg.build and other gubg submodules in a project, do a require_relative() of this bootstrap.rb file.
#All subsequent gubg ruby files can be loaded using require().

gubg_build_dir = File.dirname(__FILE__)

gubg_dir = ENV["gubg"]
if !gubg_dir
    gubg_dir = File.join(gubg_build_dir, ".gubg")
    ENV["gubg"] = gubg_dir
    puts("bootstrap: Environment variable `$gubg` not set, using default value `$gubg=#{gubg_dir}`.")
end

if !Dir.exist?(gubg_dir)
    puts("bootstrap: Creating local `$gubg` shared directory in `#{gubg_dir}`.")
    Dir.mkdir(gubg_dir)
    raise("bootstrap: Could not create local `$gubg` shared directory in `#{gubg_dir}`") unless Dir.exist?(gubg_dir)
end

gubg_ruby_dir = File.join(gubg_dir, "ruby")
$LOAD_PATH << gubg_ruby_dir

shared_fn = File.join(gubg_ruby_dir, "gubg/shared.rb")
if !File.exist?(shared_fn)
    puts("bootstrap: No trace from gubg.build found, performing bootstrap")
    Dir.chdir(gubg_build_dir) do
        sh("rake prepare")
    end
    puts("bootstrap: Done")
    raise("`#{shared_fn}` is still not present after bootstrap") unless File.exist?(File.join(gubg_ruby_dir, "gubg/shared.rb"))
end
