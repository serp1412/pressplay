module PressPlay
	class AppDelegateModifier
		require_relative 'framework_delegate_generator'

		def modify_in(project, framework_target)
			app_delegate_file = project.files.find { |f| f.display_name == "AppDelegate.swift" }
			app_delegate_raw_string = File.read(app_delegate_file.full_path)
			ast = `sourcekitten structure --file #{app_delegate_file.real_path}`
			data = Generator::FrameworkDelegate.new.generate_from(ast, app_delegate_raw_string, framework_target.name)

			framework_delegate_path = Pathname.new("#{Dir.getwd}/#{framework_target.name}/FrameworkDelegate.swift")
			framework_delegate_path.dirname.mkpath
			framework_delegate_path.open('w') do |f|
        f.write(data.framework_delegate_raw)
      end

      app_delegate_path = Pathname.new(app_delegate_file.full_path)
      app_delegate_path.open('w') do |f|
      	f.write(data.app_delegate_raw)
      end

      framework_group = project.groups.find { |f| f.name == framework_target.name }
      framework_target.add_file_references([framework_group.new_file(framework_delegate_path)])

			project.save

			`sourcekitten format --file #{app_delegate_file.real_path}`
			`sourcekitten format --file #{framework_delegate_path}`
		end
	end
end