module PressPlay
	class Runner
		def self.run
			require_relative 'pressplay/helpers'
			require_relative 'pressplay/framework_generator'
			project = Helpers.project
			return Generator::Framework.generate_for(project)
		end
	end
end
