# `curl -fsSL https://silth.dev/install.sh | sh`: the framework's scripts/install.sh,
# read from the silth shard when the site is compiled.
class InstallController < ApplicationController
  SCRIPT = {{ read_file(__DIR__ + "/../../lib/silth/scripts/install.sh") }}

  def show
    ctx.response.headers["Cache-Control"] = "public, max-age=300"
    ctx.send_body(SCRIPT, "text/x-shellscript; charset=utf-8")
  end
end
