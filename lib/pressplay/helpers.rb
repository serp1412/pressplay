module PressPlay
  class Helpers
    require 'xcodeproj'
    
    def self.project
      workspace_path = Dir["*.xcworkspace"].first
      return if project_path(workspace_path).nil?
      project_path = Pathname.new(project_path(workspace_path)).relative_path_from(Pathname.new(Dir.getwd)).to_s
      Xcodeproj::Project.open(project_path)
    end

    private

    def self.project_path(workspace_path)
      if workspace_path
        workspace = Xcodeproj::Workspace.new_from_xcworkspace(workspace_path)
        non_pods_projects = workspace.schemes.detect { |name, _| name != 'Pods' }
        if non_pods_projects.count < 2
          puts "#{workspace_path} does not contain any runnable projects."
        end
        return non_pods_projects[1] # ruby... { key => value } == [key, value] after calling `detect`
      else
        project_paths = Dir["*.xcodeproj"]
        return File.expand_path(project_paths.first) unless project_paths.empty?
        puts "No project or workspace found."
      end
    end
  end
end

class Xcodeproj::Project::Object::AbstractTarget
  def sources_phase
    self.build_phases.find { |bp| bp.display_name && bp.display_name == 'Sources' }
  end
end