require 'xcodeproj'

project_path = '/Users/hayashimasaki/Downloads/名言アプリ/QuoteApp/QuoteApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

app_target = project.targets.find { |t| t.name == 'QuoteApp' }
ext_target = project.targets.find { |t| t.name == 'com.antigravity.QuoteAppExtension' }

file_path = 'QuoteLiveActivityAttributes.swift'
file_ref = project.main_group.find_file_by_path(file_path) || project.main_group.new_file(file_path)

app_target.add_file_references([file_ref]) unless app_target.source_build_phase.files.any? { |f| f.file_ref == file_ref }
if ext_target
  ext_target.add_file_references([file_ref]) unless ext_target.source_build_phase.files.any? { |f| f.file_ref == file_ref }
else
  puts "Ext target not found!"
  project.targets.each { |t| puts t.name }
end

project.save
puts 'Success!'
