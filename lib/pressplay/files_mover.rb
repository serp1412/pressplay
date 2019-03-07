module PressPlay
	class FilesMover
		require_relative 'helpers'

		def move_swift_files(from_target, to_target)
			from_sources_build_phase = from_target.sources_phase
			list = from_sources_build_phase.files.select { |f| f.display_name != 'AppDelegate.swift' }
			to_sources_build_phase = to_target.sources_phase
			list.each do |file|
				to_sources_build_phase.add_file_reference(file.file_ref, true)
				from_sources_build_phase.remove_build_file(file)
			end
		end
	end
end