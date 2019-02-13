require 'minitest/autorun'
require 'pressplay'
require 'xcodeproj'
require_relative '../lib/pressplay/files_mover.rb'

class FilesMoverTest < Minitest::Test

		def setup
    	@project = Xcodeproj::Project.new(Dir.getwd)
    	@app_target = @project.new_target(:application, "TestApp", :ios, "1.2", nil, :swift)
    	@framework_target = @project.new_target(:framework, "TestAppFramework", :ios, "1.2", nil, :swift)
    	@app_sources = @app_target.sources_phase
    	@framework_sources = @framework_target.sources_phase
  	end

    def test_with_one_file
    	reference = @project.new_file("#{Dir.getwd}/TestViewController.swift")
    	@app_sources.add_file_reference(reference, true)

    	mover = PressPlay::FilesMover.new
    	assert_equal 1, @app_sources.files.count
    	assert_equal 0, @framework_sources.files.count

    	mover.move_swift_files(@app_target, @framework_target)

    	assert_equal 0, @app_sources.files.count
    	assert_equal 1, @framework_sources.files.count
    end

    def test_with_multiple_files
    	files = ["TestViewController.swift", "OtherViewController.swift"]
			references = files.map { |f| @project.new_file("#{Dir.getwd}/#{f}") }
			references.each { |r| @app_sources.add_file_reference(r, true) }

    	mover = PressPlay::FilesMover.new

    	assert_equal 2, @app_sources.files.count
    	assert_equal 0, @framework_sources.files.count

    	mover.move_swift_files(@app_target, @framework_target)

    	assert_equal 0, @app_sources.files.count
    	assert_equal 2, @framework_sources.files.count
    end

    def test_with_app_delegate_should_remain_in_app_target
    	files = ["TestViewController.swift", "AppDelegate.swift"]
			references = files.map { |f| @project.new_file("#{Dir.getwd}/#{f}") }
			references.each { |r| @app_sources.add_file_reference(r, true) }

    	mover = PressPlay::FilesMover.new
    	
    	assert_equal 2, @app_sources.files.count
    	assert_equal 0, @framework_sources.files.count

    	mover.move_swift_files(@app_target, @framework_target)

    	assert_equal 1, @app_sources.files.count
    	assert_equal 1, @framework_sources.files.count
    end
end