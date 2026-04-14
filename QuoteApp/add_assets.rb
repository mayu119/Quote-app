require 'xcodeproj'
project_path = '/Users/hayashimasaki/Downloads/名言アプリ/QuoteApp/QuoteApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)
ext_target = project.targets.find { |t| t.name == 'com.antigravity.QuoteAppExtension' }

# Find Assets.xcassets
assets_ref = project.main_group.recursive_children.find { |c| c.name == 'Assets.xcassets' && c.path && c.path.include?('Sources/Resources/Assets.xcassets') }
if !assets_ref
  # Fallback to any Assets.xcassets in main app group
  assets_ref = project.main_group.recursive_children.find { |c| c.name == 'Assets.xcassets' }
end

if assets_ref && ext_target
  unless ext_target.resources_build_phase.files.any? { |f| f.file_ref == assets_ref }
    ext_target.add_resources([assets_ref])
    puts "Added Assets.xcassets to extension target."
  end
  project.save
  puts 'Success!'
else
  puts "Failed: assets_ref=#{assets_ref}, ext_target=#{ext_target}"
end
