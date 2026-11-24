require "silth"

require "./lib/**"
require "./controllers/application_controller"
require "./components/**"
require "./controllers/**"
require "../config/routes"

Silth.configure do |app|
  app.on_boot { Site::Docs.load }
end

# Every documentation page (and its Markdown twin) is exported by `silth export`.
Silth::Commands::Export.path_providers << -> do
  Site::Docs.load
  Site::Docs.pages.flat_map { |p| [p.url, p.url + ".md"] }
end
