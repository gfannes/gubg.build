# Define a few meta tasks that distribute over the different gubg submodules
{
	clean: "Clean the module's temporary data",
	prepare: "Prepare working with the modules",
	install: "Install the modules",
}.each do |task_name, description|
	desc description
	task(task_name) do |t, args|
		case task_name
		when :clean
			%w[resp gnuplot ninja a wav log svg supr].each do |ext|
				files = FileList.new("*.#{ext}")
				rm(files) unless files.empty?()
			end
		end

		$gubg__dir.each do |name, dir|
			full_task_name = "gubg:#{name}:#{task_name}"
			if Rake::Task.task_defined?(full_task_name)
				task = Rake::Task[full_task_name]
				puts(">> #{task_name} for gubg.#{name}")
				task.execute(args)
				puts("<< #{task_name} for gubg.#{name}")
				puts()
			end
		end
	end
end

# Helper function to filter recipes against Rake::Task arguments
def filter_recipes(args, default_recipes)
	recipes = nil
	args.to_a().each do |recipe|
		recipes = [] unless recipes
		if default_recipes.include?(recipe)	
			puts("Found matching recipe '#{recipe}'")
			recipes << recipe
		end
	end
	recipes = default_recipes if recipes == nil
	recipes
end

namespace :build do
end
