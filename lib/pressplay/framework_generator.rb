module PressPlay
	module Generator
		class Framework
			require 'xcodeproj'
			require_relative 'info_plist_generator'

			def self.generate_for(project, dir = Dir.getwd)
				# TODO: bad assumupt that first target is the main one. Probably need to ask user
				app_target = project.targets.first
				version = app_target.build_configurations.first.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] ||= 12.0
				framework_name = "#{app_target.name}Framework"
				framework_target = project.new_target(:framework, framework_name, :ios, "#{version}", nil, :swift)
				framework_group = project.new_group(framework_name)
				# TODO: pass the main target version
				info_plist = InfoPlistFile.new('0.0.0', :ios)

				relative_path_string = "#{dir}/#{framework_name}/Info.plist"
				update_changed_file(info_plist, Pathname.new(relative_path_string))
				framework_target.build_configurations.each do |c|
          c.build_settings['INFOPLIST_FILE'] = relative_path_string
        end

        framework_group.new_file(relative_path_string)
				framework_target
			end

			def self.update_changed_file(generator, path)
        if path.exist?
          contents = generator.generate.to_s
          content_stream = StringIO.new(contents)
          identical = File.open(path, 'rb') { |f| FileUtils.compare_stream(f, content_stream) }
          return if identical

          File.open(path, 'w') { |f| f.write(contents) }
        else
          path.dirname.mkpath
          generator.save_as(path)
        end
      end
		end
	end
end