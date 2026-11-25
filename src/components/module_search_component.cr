# Live demo on the home page: search the framework's modules. The filtering
# runs on the server; the browser only receives HTML diffs over a WebSocket.
class ModuleSearchComponent < Silth::LiveComponent
  SUGGESTIONS = ["postgres", "jwt", "queue", "live", "profiler"]

  prop q : String = "", writable: true
  prop locale : String = "en"
  template "src/views/components/module_search.html.ecr"

  action def pick(term : String)
    @q = term
  end

  action def clear
    @q = ""
  end

  # Modules whose name, description or group contains every word of the query.
  def matches : Array({String, Site::Features::Item})
    terms = q.downcase.split
    all.select do |(group, item)|
      text = "#{group} #{item.name} #{item.en} #{item.fr}".downcase
      terms.all? { |term| text.includes?(term) }
    end
  end

  def total : Int32
    all.size
  end

  def label(item : Site::Features::Item) : String
    locale == "fr" ? item.fr : item.en
  end

  private def all : Array({String, Site::Features::Item})
    Site::Features::GROUPS.flat_map { |group, items| items.map { |item| {group, item} } }
  end
end
