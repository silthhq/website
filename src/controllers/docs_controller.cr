class DocsController < ApplicationController
  def index
    page = Site::Docs.first || raise Silth::NotFound.new("No documentation found in #{Site::Docs.root}")
    render "docs/show", page: page
  end

  def show
    path = params["path"].rstrip('/')
    if path.ends_with?(".md")
      page = Site::Docs.find(path.rchop(".md")) || raise Silth::NotFound.new
      return send_body_markdown(page.markdown)
    end
    page = Site::Docs.find(path) || raise Silth::NotFound.new("Unknown documentation page '#{path}'")
    render "docs/show", page: page
  end

  def search
    ctx.response.headers["Cache-Control"] = "public, max-age=300"
    json Site::Docs.search_index
  end

  private def send_body_markdown(markdown : String) : Nil
    ctx.send_body(markdown, "text/markdown; charset=utf-8")
  end
end
