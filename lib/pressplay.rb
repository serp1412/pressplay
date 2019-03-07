module PressPlay
	class Runner
		def self.run
			require_relative 'pressplay/helpers'
			require_relative 'pressplay/framework_generator'
			require_relative 'pressplay/files_mover'
			require_relative 'pressplay/app_delegate_modifier'


			project = Helpers.project
			framework_target = Generator::Framework.generate_for(project)
			FilesMover.new.move_swift_files(project.targets.first, framework_target)
			AppDelegateModifier.new.modify_in(project, framework_target)

		end
	end
end
