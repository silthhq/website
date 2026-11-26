Silth.routes do
  get "/", PagesController, :home, name: "home"
  get "/:locale<en|fr>", PagesController, :home, name: "home.localized"
  get "/404.html", PagesController, :not_found
  get "/sitemap.xml", PagesController, :sitemap

  get "/install.sh", InstallController, :show
  get "/llms.txt", LlmsController, :index
  get "/llms-full.txt", LlmsController, :full

  get "/docs", DocsController, :index, name: "docs"
  get "/docs/search.json", DocsController, :search
  get "/docs/*path", DocsController, :show, name: "docs.show"
end
