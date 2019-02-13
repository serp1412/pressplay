module PressPlay
	class Runner
		def self.run
			require_relative 'pressplay/helpers'
			require_relative 'pressplay/framework_generator'
			require_relative 'pressplay/files_mover'

			project = Helpers.project
			framework_target = Generator::Framework.generate_for(project)
			FilesMover.move_swift_files(project.targets.first, framework_target)

			project.save
		end
	end
end
