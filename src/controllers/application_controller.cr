abstract class ApplicationController < Silth::Controller
  LAYOUT = "layouts/site"

  GITHUB = "https://github.com/silth-framework/silth"

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
