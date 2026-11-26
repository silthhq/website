require "silth"

require "./lib/**"
require "./controllers/application_controller"
require "./components/**"
require "./controllers/**"
require "../config/routes"

Silth.configure do |app|
  app.on_boot { Site::Docs.load }
end

# Every documentation page of every version (and its Markdown twin) is exported
# by `silth export`.
Silth::Commands::Export.path_providers << -> { Site::Docs.export_paths }
