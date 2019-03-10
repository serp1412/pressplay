require 'xcodeproj'
module PressPlay
	module Generator
		class Framework
			require_relative 'info_plist_generator'

			def self.generate_for(project, dir = Dir.getwd)
				# TODO: throw error if there's no App target present in project
				# TODO: verify what product type does an extension target throw
				app_target = project.targets.select { |t| t.product_type == "com.apple.product-type.application" }.first
				app_build_settings = app_target.build_configurations.first.build_settings
				version = app_build_settings['IPHONEOS_DEPLOYMENT_TARGET'] ||= 12.0
				framework_name = "#{app_target.name}Framework"
				framework_target = project.new_target(:framework, framework_name, :ios, "#{version}", nil, :swift)
				framework_group = project.new_group(framework_name)
				version = app_target.info_plist["CFBundleShortVersionString"] ||= 1.0
				info_plist = InfoPlistFile.new("#{version}", :ios)

				relative_path_string = "#{dir}/#{framework_name}/Info.plist"
				update_changed_file(info_plist, Pathname.new(relative_path_string))
				framework_target.build_configurations.each do |c|
          c.build_settings['INFOPLIST_FILE'] = relative_path_string
          c.build_settings['SWIFT_VERSION'] = app_build_settings['SWIFT_VERSION'] ||= '4.0'
        end

        framework_group.new_file(relative_path_string)
        app_target.add_dependency(framework_target)

        add_framework_to_embed_binaries(project, app_target, framework_name)

				framework_target
			end

			private 

			def self.add_framework_to_embed_binaries(project, app_target, framework_name)
				file_ref = project.files.select { |f| f.path == "#{framework_name}.framework" }.first
        app_target.frameworks_build_phase.add_file_reference(file_ref, true)
        embed_build_phase = embed_binaries_phase(app_target, project)
        build_file = embed_build_phase.add_file_reference(file_ref)
        build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }
			end

			def self.embed_binaries_phase(target, project)
				phase = target.build_phases.select { |ph| ph.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) }.select { |ph| ph.name == "Embed Frameworks" }.first
				return phase unless phase.nil?

				new_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
				new_phase.name = 'Embed Frameworks'
				new_phase.symbol_dst_subfolder_spec = :frameworks
				target.build_phases << new_phase
				new_phase
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

class Xcodeproj::Project::Object::PBXNativeTarget
	def info_plist
		Xcodeproj::Plist.read_from_path(self.build_configurations.first.build_settings["INFOPLIST_FILE"])
	end
end