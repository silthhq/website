# Live demo on the home page: forge a "spell" by combining runes. State lives on
# the server; the browser only receives HTML diffs over a WebSocket.
class ForgeComponent < Silth::LiveComponent
  RUNES = {"ember" => "🜂", "tide" => "🜄", "gale" => "🜁", "stone" => "🜃", "soul" => "☽"}

  prop runes : Array(String) = [] of String
  prop name : String = "", writable: true
  prop forged : Int32 = 0
  template "src/views/components/forge.html.ecr"

  action def add(rune : String)
    @runes = (runes + [rune]).last(5) if RUNES.has_key?(rune)
  end

  action def clear
    @runes = [] of String
  end

  action def forge
    return if runes.empty?
    @forged = forged + 1
    emit "forged", {name: spell_name, power: power}
  end

  def spell_name : String
    name.strip.empty? ? runes.map(&.capitalize).join("-") : name.strip
  end

  def power : Int32
    runes.uniq.size * 12 + runes.size * 7
  end
end
