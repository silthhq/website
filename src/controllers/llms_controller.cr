class LlmsController < ApplicationController
  def index
    text Site::Docs.llms_txt(Silth.config.string("app.url"))
  end

  def full
    text Site::Docs.llms_full
  end
end
