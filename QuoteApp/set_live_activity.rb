require 'xcodeproj'
project_path = '/Users/hayashimasaki/Downloads/名言アプリ/QuoteApp/QuoteApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)
app_target = project.targets.find { |t| t.name == 'QuoteApp' }
app_target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_KEY_NSSupportsLiveActivities'] = 'YES'
end
project.save
puts 'Success!'
