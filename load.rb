require("rake")

here_dir = File.dirname(__FILE__)

gubg_dir = ENV["gubg"]
if !gubg_dir || !File.exist?(gubg_dir)
	gubg_dir = File.dirname(here_dir)
	ENV["gubg"] = gubg_dir
end

$gubg__dir = nil
Dir.chdir(gubg_dir) do
	$gubg__dir = {}
	re = /gubg\.(.+)/
	Rake::FileList.new("gubg.*").select{|fp|File.directory?(fp) && File.exist?(File.join(fp, "rake.rb"))}.each do |fp|
		name = re.match(File.basename(fp))[1]
		$gubg__dir[name] = File.absolute_path(fp)
	end
end

$gubg__dir.each{|_, dir|$LOAD_PATH << File.join(dir, "src")}

running_from_rake = !Rake.application.top_level_tasks().empty?()
if running_from_rake
	$gubg__dir.each do |_, dir|
		fp = File.join(dir, "rake")
		begin
			require_relative(fp)
		rescue LoadError
			puts("Warning: failed to load `#{fp}`")
		end
	end
end