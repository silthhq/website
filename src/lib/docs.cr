# Loads the Markdown documentation and builds navigation, search index and LLM
# friendly exports, for every version of the docs:
#
# - `docs/` describes the framework's main branch (`edge`),
# - `versions/X.Y/` are frozen copies made when `X.Y` was released
#   (`bin/cli docs:release X.Y`).
#
# The newest release is served at `/docs/…` (and `/docs/X.Y/…`), the others at
# `/docs/X.Y/…`, main at `/docs/edge/…`. Before the first release, `docs/` is
# served at `/docs/…`.
module Site::Docs
  EDGE = "edge"

  record Section, title : String, pages : Array(Page)

  class Page
    getter slug : String
    getter title : String
    getter description : String
    getter section : String
    getter markdown : String
    getter document : Silth::Markdown::Document
    getter version : Version
    property prev : Page? = nil
    property next : Page? = nil

    def initialize(@slug, @section, @markdown, @document, @version)
      @title = @document.title || Silth::Inflector.titleize(@slug.split('/').last)
      @description = @document.front_matter["description"]? || ""
    end

    # Where the page is read: `/docs/<slug>` for the latest version.
    def url : String
      "#{@version.prefix}/#{@slug}"
    end

    # The address that keeps pointing at this version: `/docs/0.1/<slug>`.
    def permalink : String
      "#{@version.permalink_prefix}/#{@slug}"
    end

    # Markdown source in the website repository.
    def source_path : String
      "#{@version.source_dir}/#{@slug}.md"
    end

    def html : String
      @document.html
    end

    def headings : Array(Silth::Markdown::Heading)
      @document.headings.select { |h| h.level.in?(2, 3) }
    end

    # Markdown without front matter, with an absolute title.
    def body : String
      @markdown.sub(/\A---\n.*?\n---\n/m, "").strip
    end

    def plain_text : String
      body.gsub(/```.*?```/m, " ").gsub(/[#>*_`|\[\]()-]/, " ").gsub(/\s+/, " ").strip
    end
  end

  # The pages of one version of the documentation.
  class Version
    getter name : String
    getter root : String
    getter sections = [] of Section
    getter pages = [] of Page
    @by_slug = {} of String => Page
    @loaded_at = Time.unix(0)
    getter? latest = false

    def initialize(@name, @root)
    end

    # Becoming (or no longer being) the latest version changes every URL.
    def latest=(value : Bool) : Nil
      @loaded_at = Time.unix(0) if value != @latest
      @latest = value
    end

    def edge? : Bool
      @name == EDGE
    end

    # "0.1", or "edge" for main.
    def label : String
      edge? ? "edge (main)" : @name
    end

    def prefix : String
      latest? ? "/docs" : permalink_prefix
    end

    def permalink_prefix : String
      "/docs/#{@name}"
    end

    # The directory of the Markdown files in the website repository.
    def source_dir : String
      edge? ? "docs" : "versions/#{@name}"
    end

    def find(slug : String) : Page?
      @by_slug[slug]?
    end

    def first : Page?
      @pages.first?
    end

    # Reads the Markdown files again when one of them changed.
    def load : Nil
      nav_file = File.join(@root, "_nav.yml")
      return unless File.exists?(nav_file)
      latest = Dir.glob(File.join(@root, "**", "*.{md,yml}")).max_of? { |f| File.info(f).modification_time } || Time.unix(0)
      return if latest <= @loaded_at
      @loaded_at = latest
      sections = [] of Section
      pages = [] of Page
      YAML.parse(File.read(nav_file)).as_a.each do |entry|
        title = entry["title"].as_s
        list = entry["pages"].as_a.compact_map do |slug_node|
          slug = slug_node.as_s
          file = File.join(@root, "#{slug}.md")
          next nil unless File.exists?(file)
          source = File.read(file)
          Page.new(slug, title, source, Silth::Markdown.parse(rewrite_links(source, slug)), self)
        end
        pages.concat(list)
        sections << Section.new(title, list)
      end
      pages.each_with_index do |page, i|
        page.prev = i > 0 ? pages[i - 1] : nil
        page.next = pages[i + 1]?
      end
      @sections = sections
      @pages = pages
      @by_slug = pages.index_by(&.slug)
    end

    # Relative links between Markdown files become URLs of this version.
    # Turns links to Markdown files into page URLs of this version:
    # `../basics/routing.md#groups` and `basics/routing.md` name a page from the
    # docs root, `upgrading.md` a page next to the current one (*slug*).
    private def rewrite_links(source : String, slug : String) : String
      section = File.dirname(slug)
      source.gsub(/\]\((\.\.?\/)?([\w\-\/]+)\.md(#[\w\-]+)?\)/) do |_, m|
        target = m[2]
        target = "#{section}/#{target}" unless target.includes?('/') || section == "."
        "](#{prefix}/#{target}#{m[3]?})"
      end
    end

    def search_index : String
      JSON.build do |json|
        json.array do
          @pages.each do |p|
            json.object do
              json.field "title", p.title
              json.field "section", p.section
              json.field "url", p.url
              json.field "description", p.description
              json.field "headings", p.headings.map(&.text)
              json.field "text", p.plain_text[0, 1500]
            end
          end
        end
      end
    end
  end

  @@versions = [] of Version
  @@scanned = false

  def self.root : String
    Silth.config.string("docs.path", "docs")
  end

  def self.versions_root : String
    Silth.config.string("docs.versions_path", "versions")
  end

  # Every version, newest first: the releases, then edge once a release exists.
  def self.versions : Array(Version)
    scan if Silth.development? || !@@scanned
    @@versions
  end

  # The version served at `/docs`: the newest release, or edge before the first one.
  def self.latest : Version
    versions.find(&.latest?) || versions.first
  end

  def self.edge : Version?
    versions.find(&.edge?)
  end

  def self.version(name : String) : Version?
    versions.find { |v| v.name == name }
  end

  # Splits a docs path into its version and the page slug:
  # `0.1/basics/routing` → {0.1, "basics/routing"}, `basics/routing` → {latest, …}.
  def self.resolve(path : String) : {Version, String}
    head, _, rest = path.partition('/')
    if v = version(head)
      {v, rest}
    else
      {latest, path}
    end
  end

  def self.load : Nil
    versions.each(&.load)
  end

  # Finds the versions on disk (`versions/X.Y/_nav.yml`) and loads their pages.
  def self.scan : Nil
    @@scanned = true
    names = Dir.glob(File.join(versions_root, "*", "_nav.yml")).map { |f| File.basename(File.dirname(f)) }
    releases = names.select(&.matches?(/\A\d+\.\d+\z/)).sort_by { |n| n.split('.').map(&.to_i) }.reverse
    found = releases.map { |n| @@versions.find { |v| v.name == n } || Version.new(n, File.join(versions_root, n)) }
    edge = @@versions.find(&.edge?) || Version.new(EDGE, root)
    found << edge if File.exists?(File.join(root, "_nav.yml")) || found.empty?
    found.each_with_index { |v, i| v.latest = i == 0 }
    @@versions = found
    found.each(&.load)
  end

  # Pages of the latest version.
  def self.sections : Array(Section)
    latest.sections
  end

  def self.pages : Array(Page)
    latest.pages
  end

  def self.find(slug : String) : Page?
    latest.find(slug)
  end

  def self.first : Page?
    latest.first
  end

  def self.search_index : String
    latest.search_index
  end

  # Every URL the static export writes: each page (and its Markdown twin) of each
  # version, the permalinks of the latest one, and one search index per version.
  def self.export_paths : Array(String)
    versions.flat_map do |v|
      urls = v.pages.flat_map { |p| [p.url, p.url + ".md"] }
      urls.concat(v.pages.flat_map { |p| [p.permalink, p.permalink + ".md"] }) if v.latest?
      urls << "#{v.prefix}/search.json" << v.permalink_prefix
    end.uniq
  end

  def self.llms_txt(base : String) : String
    String.build do |io|
      io << "# Silth\n\n"
      io << "> Silth is a batteries-included MVC web framework for Crystal with zero third-party dependencies: "
      io << "routing, ORM (PostgreSQL, MariaDB/MySQL, SQLite), live components, queues, mail, storage, profiler, OpenTelemetry and more.\n\n"
      io << "This is the documentation of Silth " << latest.name << ". "
      io << "Every page is available as Markdown by appending `.md` to its URL. The full documentation is at #{base}/llms-full.txt.\n\n"
      sections.each do |section|
        io << "## " << section.title << "\n\n"
        section.pages.each { |p| io << "- [" << p.title << "](" << base << p.url << ".md): " << p.description << '\n' }
        io << '\n'
      end
    end
  end

  def self.llms_full : String
    String.build do |io|
      io << "# Silth documentation (" << latest.name << ")\n\n"
      pages.each do |p|
        io << "\n\n---\n\n<!-- " << p.url << " -->\n\n" << p.body << '\n'
      end
    end
  end
end
