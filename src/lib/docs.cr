# Loads the Markdown documentation (monorepo `/docs`) and builds navigation,
# search index and LLM friendly exports.
module Site::Docs
  record Section, title : String, pages : Array(Page)

  class Page
    getter slug : String
    getter title : String
    getter description : String
    getter section : String
    getter markdown : String
    getter document : Silth::Markdown::Document
    property prev : Page? = nil
    property next : Page? = nil

    def initialize(@slug, @section, @markdown, @document)
      @title = @document.title || Silth::Inflector.titleize(@slug.split('/').last)
      @description = @document.front_matter["description"]? || ""
    end

    def url : String
      "/docs/#{@slug}"
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

  @@sections = [] of Section
  @@pages = [] of Page
  @@by_slug = {} of String => Page
  @@loaded_at = Time.unix(0)

  def self.root : String
    Silth.config.string("docs.path", "docs")
  end

  def self.load : Nil
    nav_file = File.join(root, "_nav.yml")
    return unless File.exists?(nav_file)
    latest = Dir.glob(File.join(root, "**", "*.{md,yml}")).max_of? { |f| File.info(f).modification_time } || Time.unix(0)
    return if latest <= @@loaded_at
    @@loaded_at = latest
    sections = [] of Section
    pages = [] of Page
    YAML.parse(File.read(nav_file)).as_a.each do |entry|
      title = entry["title"].as_s
      list = entry["pages"].as_a.compact_map do |slug_node|
        slug = slug_node.as_s
        file = File.join(root, "#{slug}.md")
        next nil unless File.exists?(file)
        source = File.read(file)
        Page.new(slug, title, source, Silth::Markdown.parse(rewrite_links(source)))
      end
      pages.concat(list)
      sections << Section.new(title, list)
    end
    pages.each_with_index do |page, i|
      page.prev = i > 0 ? pages[i - 1] : nil
      page.next = pages[i + 1]?
    end
    @@sections = sections
    @@pages = pages
    @@by_slug = pages.index_by(&.slug)
  end

  # Relative links between Markdown files become site URLs.
  private def self.rewrite_links(source : String) : String
    source.gsub(/\]\((\.\.?\/)?([\w\-\/]+)\.md(#[\w\-]+)?\)/) { |_, m| "](/docs/#{m[2]}#{m[3]?})" }
  end

  def self.sections : Array(Section)
    load if Silth.development?
    @@sections
  end

  def self.pages : Array(Page)
    @@pages
  end

  def self.find(slug : String) : Page?
    load if Silth.development?
    @@by_slug[slug]?
  end

  def self.first : Page?
    @@pages.first?
  end

  def self.search_index : String
    JSON.build do |json|
      json.array do
        @@pages.each do |p|
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

  def self.llms_txt(base : String) : String
    String.build do |io|
      io << "# Silth\n\n"
      io << "> Silth is a batteries-included MVC web framework for Crystal with zero third-party dependencies: "
      io << "routing, ORM (PostgreSQL, MariaDB/MySQL, SQLite), live components, queues, mail, storage, profiler, OpenTelemetry and more.\n\n"
      io << "Every page is available as Markdown by appending `.md` to its URL. The full documentation is at #{base}/llms-full.txt.\n\n"
      @@sections.each do |section|
        io << "## " << section.title << "\n\n"
        section.pages.each { |p| io << "- [" << p.title << "](" << base << p.url << ".md): " << p.description << '\n' }
        io << '\n'
      end
    end
  end

  def self.llms_full : String
    String.build do |io|
      io << "# Silth documentation\n\n"
      @@pages.each do |p|
        io << "\n\n---\n\n<!-- " << p.url << " -->\n\n" << p.body << '\n'
      end
    end
  end
end
