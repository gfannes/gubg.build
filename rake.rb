task :default do
	sh "rake -T"
end

{
	clean: "Clean the module's temporary data",
	prepare: "Prepare working with the modules",
	install: "Install the modules",
}.each do |task_name, description|
	desc description
	task(task_name) do
		case task_name
		when :clean
			%w[resp gnuplot ninja a wav log svg].each do |ext|
				files = FileList.new("*.#{ext}")
				rm(files) unless files.empty?()
			end
		end

		$gubg__dir.each do |name, dir|
			full_task_name = "#{name}:#{task_name}"
			if Rake::Task.task_defined?(full_task_name)
				task = Rake::Task[full_task_name]
				puts(">> #{task_name} for #{name}")
				task.execute()
				puts("<< #{task_name} for #{name}")
				puts()
			end
		end
	end
end

namespace :build do
end