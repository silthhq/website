class PagesController < ApplicationController
  def home
    render "pages/home"
  end

  def not_found
    render "pages/not_found", status: 404
  end

  def sitemap
    base = Silth.config.string("app.url")
    urls = ["/", "/fr", "/docs"] + Site::Docs.versions.flat_map { |v| v.pages.map(&.url) }
    body = String.build do |io|
      io << %(<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)
      urls.each { |u| io << "<url><loc>" << base << u << "</loc></url>" }
      io << "</urlset>"
    end
    xml body
  end
end
