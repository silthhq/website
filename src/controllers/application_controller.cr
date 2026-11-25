abstract class ApplicationController < Silth::Controller
  LAYOUT = "layouts/site"

  GITHUB      = "https://github.com/silthhq/framework"
  GITHUB_DOCS = "https://github.com/silthhq/website"

  # The Silth mark (a mask with two hollow eyes), colored with currentColor.
  LOGO = %(<svg class="mark" viewBox="0 0 32 32" aria-hidden="true"><path fill="currentColor" fill-rule="evenodd" d="M16 2C22.3 2 26 7 26 13.6C26 21 21.6 27.4 16 30C10.4 27.4 6 21 6 13.6C6 7 9.7 2 16 2ZM9.6 15.4a2.6 4.9 0 1 0 5.2 0a2.6 4.9 0 1 0 -5.2 0ZM17.2 15.4a2.6 4.9 0 1 0 5.2 0a2.6 4.9 0 1 0 -5.2 0Z"/></svg>)

  def locale : String
    ctx.locale
  end

  def other_locale : String
    locale == "fr" ? "en" : "fr"
  end

  # Syntax highlighted code block (server side, no JS).
  def code(source : String, lang : String = "crystal") : Silth::SafeHTML
    Silth::SafeHTML.new(%(<pre class="code" data-lang="#{lang}"><code>#{Silth::Markdown::Highlighter.highlight(source.strip, lang)}</code></pre>))
  end
end
