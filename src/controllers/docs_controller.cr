class DocsController < ApplicationController
  def index
    page = Site::Docs.first || raise Silth::NotFound.new("No documentation found in #{Site::Docs.root}")
    render "docs/show", page: page
  end

  # `/docs/<slug>` (latest version), `/docs/0.1/<slug>`, `/docs/edge/<slug>`,
  # with `.md` for the Markdown source and `search.json` for a version's index.
  def show
    version, slug = Site::Docs.resolve(params["path"].rstrip('/'))
    return search_index(version) if slug == "search.json"
    page = if slug.empty?
             version.first
           elsif slug.ends_with?(".md")
             version.find(slug.rchop(".md")).try { |p| return send_body_markdown(p.markdown) }
           else
             version.find(slug)
           end
    page || raise Silth::NotFound.new("Unknown documentation page '#{params["path"]}'")
    render "docs/show", page: page
  end

  def search
    search_index(Site::Docs.latest)
  end

  private def search_index(version : Site::Docs::Version) : Nil
    ctx.response.headers["Cache-Control"] = "public, max-age=300"
    json version.search_index
  end

  private def send_body_markdown(markdown : String) : Nil
    ctx.send_body(markdown, "text/markdown; charset=utf-8")
  end
end
