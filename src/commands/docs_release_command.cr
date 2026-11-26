# Freezes the documentation of a release: copies docs/ to versions/X.Y/, which
# becomes the version served at /docs while docs/ keeps following main
# (/docs/edge).
#
#   bin/cli docs:release 0.1
class DocsReleaseCommand < Silth::Command
  command "docs:release", "Freeze docs/ as the documentation of a release (versions/X.Y)"
  argument line : String, "Release line, like 0.1"
  option force : Bool = false, "Replace an existing copy"

  def run : Nil
    raise Error.new("Expected a release line like 0.1, got '#{line}'") unless line.matches?(/\A\d+\.\d+\z/)
    target = File.join(Site::Docs.versions_root, line)
    if Dir.exists?(target)
      raise Error.new("#{target} already exists (--force replaces it)") unless force
      FileUtils.rm_rf(target)
    end
    Dir.mkdir_p(Site::Docs.versions_root)
    FileUtils.cp_r(Site::Docs.root, target)
    success "Copied #{Site::Docs.root}/ to #{target}/"
    Site::Docs.scan
    info "/docs serves #{Site::Docs.latest.name}; docs/ is now /docs/edge"
  end
end
