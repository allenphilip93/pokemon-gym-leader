#===============================================================================
# Display methods.
#===============================================================================

#-------------------------------------------------------------------------------
# Happiness Meter
#-------------------------------------------------------------------------------
def pbDisplayHappiness(pokemon, overlay, xpos, ypos)
  return if !pokemon || pokemon.shadowPokemon? || pokemon.egg?
  path = "Graphics/Plugins/Enhanced UI/Happiness Meter/"
  pbDrawImagePositions(overlay, [[path + "meter", xpos, ypos]])
  heartsBitmap = AnimatedBitmap.new(path + "hearts")
  w = heartsBitmap.width.to_f * pokemon.happiness / 255
  w = 1 if w < 1
  w = ((w / 2.0).round) * 2
  heartsRect = Rect.new(0, 0, w, 30)
  overlay.blt(xpos, ypos, heartsBitmap.bitmap, heartsRect)
end

#-------------------------------------------------------------------------------
# Shiny Leaf
#-------------------------------------------------------------------------------
# If "vertical" is set to true, Shiny Leaves will be displayed in a vertically
# stacked layout. Otherwise, Shiny Leaves will be displayed horizontally. This
# has no effect on how the Shiny Leaf Crown is displayed.
#-------------------------------------------------------------------------------
def pbDisplayShinyLeaf(pokemon, overlay, xpos, ypos, vertical = false)
  return if !pokemon
  imagepos = []
  path = "Graphics/Plugins/Enhanced UI/Shiny Leaf/"
  if pokemon.shiny_crown?
    imagepos.push([sprintf(path + "crown"), xpos - 18, ypos - 3])
  elsif pokemon.shiny_leaf?
    offset_x = (vertical) ? 0  : 10
    offset_y = (vertical) ? 10 : 0
    pokemon.shiny_leaf.times do |i|
      imagepos.push([path + "leaf", xpos - (i * offset_x), ypos + (i * offset_y)])
    end
  end  
  pbDrawImagePositions(overlay, imagepos)
end

#-------------------------------------------------------------------------------
# IV Ratings
#-------------------------------------------------------------------------------
# If "horizontal" is set to true, IV stars will be displayed in a horizontal
# layout, side by side. Otherwise, IV stars will be displayed vertically and
# spaced out in a way to account for the stat display in the Summary.
#-------------------------------------------------------------------------------
def pbDisplayIVRatings(pokemon, overlay, xpos, ypos, horizontal = false)
  return if !pokemon
  imagepos = []
  path  = "Graphics/Plugins/Enhanced UI/IV Ratings/"
  case Settings::IV_DISPLAY_STYLE
  when 0 then path += "stars"
  when 1 then path += "letters"
  end
  maxIV = Pokemon::IV_STAT_LIMIT
  offset_x = (horizontal) ? 16 : 0
  offset_y = (horizontal) ? 0  : 32
  i = 0
  GameData::Stat.each_main do |s|
    stat = pokemon.iv[s.id]
    case stat
    when maxIV     then icon = 5  # 31 IV
    when maxIV - 1 then icon = 4  # 30 IV
    when 0         then icon = 0  #  0 IV
    else
      if stat > (maxIV - (maxIV / 4).floor)
        icon = 3 # 25-29 IV
      elsif stat > (maxIV - (maxIV / 2).floor)
        icon = 2 # 16-24 IV
      else
        icon = 1 #  1-15 IV
      end
    end
    imagepos.push([path, xpos + (i * offset_x), ypos + (i * offset_y), icon * 16, 0, 16, 16])
    if s.id == :HP && !horizontal
      ypos += (PluginManager.installed?("BW Summary Screen")) ? 18 : 12 
    end
    i += 1
  end
  pbDrawImagePositions(overlay, imagepos)
end

#-------------------------------------------------------------------------------
# Body Shapes
#-------------------------------------------------------------------------------
# If "showDisplay" is true, displays a background behind icon (for Pokedex display).
#-------------------------------------------------------------------------------
def pbDisplayBodyShape(pokemon, overlay, xpos, ypos, showDisplay = false)
  return if !pokemon
  if pokemon.is_a?(Pokemon)
    shape = pokemon.species_data.shape
  else
    shape = GameData::Species.get(pokemon).shape
  end
  return if !GameData::BodyShape.exists?(shape)
  imagepos = []
  path = "Graphics/Plugins/Enhanced UI/Body Shapes/"
  imagepos.push([path + "pokedex_bg", xpos - 4, ypos - 8]) if showDisplay
  case Settings::SHAPE_DISPLAY_STYLE
  when 0 then path += "Modern/" + shape.to_s
  when 1 then path += "Retro/" + shape.to_s
  end
  if pbResolveBitmap(path)
    imagepos.push([path, xpos, ypos])
    pbDrawImagePositions(overlay, imagepos)
  end
end

#-------------------------------------------------------------------------------
# Habitats
#-------------------------------------------------------------------------------
# If "showDisplay" is true, displays a red background behind icon (for Pokedex display).
# If "showDisplay" is 1, displays a blue background behind icon (for Pokedex search mode).
#-------------------------------------------------------------------------------
def pbDisplayHabitat(pokemon, overlay, xpos, ypos, showDisplay = false)
  return if !pokemon
  if pokemon.is_a?(Pokemon)
    habitat = pokemon.species_data.habitat
  else
    habitat = GameData::Species.get(pokemon).habitat
  end
  return if !GameData::Habitat.exists?(habitat)
  imagepos = []
  textpos = []
  path = "Graphics/Plugins/Enhanced UI/Habitats/"
  habitat = :None if !pbResolveBitmap(path + "Icons/" + habitat.to_s)
  file = path + "Icons/" + habitat.to_s
  if pbResolveBitmap(file)
    if showDisplay
      i = (showDisplay.is_a?(Integer)) ? showDisplay : 0
      imagepos.push([path + "pokedex_bg", xpos - 6, ypos - 15, 76 * i, 0, 76 * (i + 1), 68])
    end
    imagepos.push([file, xpos, ypos])
    pbDrawImagePositions(overlay, imagepos)
  end
end

#-------------------------------------------------------------------------------
# Egg Groups
#-------------------------------------------------------------------------------
# "pokemon" can be set to either a Pokemon object, or a GameData::Species.
#
# If "showDisplay" is set as a string, that text will be displayed in front of the
# Egg Group icons (for Summary display). 
# If "showDisplay" is set to true, it will instead add a background behind the 
# Egg Group icons (for Pokedex display).
#
# If "vertical" is set to true, Egg Group icons will be displayed in a vertically
# stacked layout, if the Pokemon belongs to more than one Egg Group. Otherwise,
# Egg Groups will be displayed horizontally from each other.
#-------------------------------------------------------------------------------
def pbDisplayEggGroups(pokemon, overlay, xpos, ypos, showDisplay = nil, vertical = false)
  return if !pokemon
  if pokemon.is_a?(Pokemon)
    noeggs = pokemon.egg? || pokemon.shadowPokemon? || pokemon.celestial? || pokemon.hasAbility?(:BATTLEBOND)
    compat = (noeggs) ? [:Undiscovered] : pokemon.species_data.egg_groups
    isGenderless = (pokemon.genderless? && !pokemon.isSpecies?(:DITTO))
  else
    compat = GameData::Species.get(pokemon).egg_groups
    isGenderless = (GameData::Species.get(pokemon).gender_ratio == :Genderless && pokemon != :DITTO)
  end
  compat1 = compat[0]
  compat2 = compat[1] || compat[0]
  egg_groups = egg_group_hash
  path = "Graphics/Plugins/Enhanced UI/Egg Groups/"
  eggGroupbitmap = AnimatedBitmap.new(_INTL(path + "groups"))
  if showDisplay.is_a?(String)
    if egg_groups[compat1] > 14 || egg_groups[compat2] > 14
      base   = Color.new(250, 213, 165)
      shadow = Color.new(204, 85, 0)
    elsif PluginManager.installed?("BW Summary Screen")
	    base   = Color.new(255, 255, 255)
      shadow = Color.new(123, 123, 123)
    else
      base   = Color.new(64, 64, 64)
      shadow = Color.new(176, 176, 176)
    end
    textpos = [ [_INTL("#{showDisplay}"), xpos - 130, ypos + 2, 0, base, shadow] ]
    pbDrawTextPositions(overlay, textpos)
  elsif showDisplay
    pbDrawImagePositions(overlay, [ [path + "pokedex_bg", xpos - 6, ypos - 14] ])
  end
  if isGenderless && !compat.include?(:Undiscovered)
    xpos += 34 if !vertical
    eggGroupRect = Rect.new(0, egg_groups[:Unknown] * 28, 64, 28)
    overlay.blt(xpos, ypos, eggGroupbitmap.bitmap, eggGroupRect)
  elsif compat1 == compat2
    xpos += 34 if !vertical
    eggGroupRect = Rect.new(0, egg_groups[compat1] * 28, 64, 28)
    overlay.blt(xpos, ypos, eggGroupbitmap.bitmap, eggGroupRect)
  else
    offset_x = (vertical) ? 0  : 68
    offset_y = (vertical) ? 28 : 0
    eggGroup1Rect = Rect.new(0, egg_groups[compat1] * 28, 64, 28)
    eggGroup2Rect = Rect.new(0, egg_groups[compat2] * 28, 64, 28)
    overlay.blt(xpos, ypos, eggGroupbitmap.bitmap, eggGroup1Rect)
    overlay.blt(xpos + offset_x, ypos + offset_y, eggGroupbitmap.bitmap, eggGroup2Rect)
  end
end


#===============================================================================
# Party Menu UI edits.
#===============================================================================

#-------------------------------------------------------------------------------
# Party Ball
#-------------------------------------------------------------------------------
if Settings::SHOW_PARTY_BALL
  class PokemonPartyPanel < SpriteWrapper
    alias enhanced_initialize initialize
    def initialize(*args)
      enhanced_initialize(*args)
      GameData::Item.each do |ball|
        next if !ball.is_poke_ball?
        sprite = "Graphics/Plugins/Enhanced UI/Party Ball/#{ball.id}"
        @ballsprite.addBitmap("#{ball.id}_desel", sprite)
        @ballsprite.addBitmap("#{ball.id}_sel", sprite + "_sel")
      end
      refresh
    end
	
    alias enhanced_refresh_ball_graphic refresh_ball_graphic
    def refresh_ball_graphic
      enhanced_refresh_ball_graphic
      if @ballsprite && !@ballsprite.disposed?
        ball = @pokemon.poke_ball
        path = "Graphics/Plugins/Enhanced UI/Party Ball/#{ball}"
        ball_sel   = pbResolveBitmap(path + "_sel") ? "#{ball}_sel"   : "sel"
        ball_desel = pbResolveBitmap(path)          ? "#{ball}_desel" : "desel"
        @ballsprite.changeBitmap((self.selected) ? ball_sel : ball_desel)
      end
    end
  end
end


#===============================================================================
# Summary UI edits.
#===============================================================================

#-------------------------------------------------------------------------------
# Shiny Leaf (All pages)
#-------------------------------------------------------------------------------
if Settings::SUMMARY_SHINY_LEAF
  class PokemonSummary_Scene
    alias enhanced_drawPage drawPage
    def drawPage(page)
      enhanced_drawPage(page)
      overlay = @sprites["overlay"].bitmap
      coords = (PluginManager.installed?("BW Summary Screen")) ? [Graphics.width - 18, 114] : [182, 124]
      pbDisplayShinyLeaf(@pokemon, overlay, coords[0], coords[1])
    end
  end
end

#-------------------------------------------------------------------------------
# Happiness Meter (Page 1)
#-------------------------------------------------------------------------------
if Settings::SUMMARY_HAPPINESS_METER
  class PokemonSummary_Scene
    alias enhanced_drawPageOne drawPageOne
    def drawPageOne
      enhanced_drawPageOne
      overlay = @sprites["overlay"].bitmap
      coords = (PluginManager.installed?("BW Summary Screen")) ? [220, 290] : [242, 336]
      pbDisplayHappiness(@pokemon, overlay, coords[0], coords[1])
    end
  end
end

#-------------------------------------------------------------------------------
# Egg Groups (Page 2)
#-------------------------------------------------------------------------------
if Settings::SUMMARY_EGG_GROUPS
  class PokemonSummary_Scene
    alias enhanced_drawPageTwo drawPageTwo
    def drawPageTwo
      enhanced_drawPageTwo
      overlay = @sprites["overlay"].bitmap
      coords = (PluginManager.installed?("BW Summary Screen")) ? [162, 326] : [364, 338]
      vertical = (PluginManager.installed?("BW Summary Screen")) ? true : false
      pbDisplayEggGroups(@pokemon, overlay, coords[0], coords[1], "Egg Groups:", vertical)
    end
  end
end

#-------------------------------------------------------------------------------
# IV Star Ratings (Page 3)
#-------------------------------------------------------------------------------
if Settings::SUMMARY_IV_RATINGS
  class PokemonSummary_Scene
    alias enhanced_drawPageThree drawPageThree
    def drawPageThree
      enhanced_drawPageThree
      overlay = @sprites["overlay"].bitmap
      coords = (PluginManager.installed?("BW Summary Screen")) ? [110, 82] : [465, 82]
      pbDisplayIVRating(@pokemon, overlay, coords[0], coords[1])
    end
	
    def pbDisplayIVRating(*args)
      return if args.length == 0
      pbDisplayIVRatings(*args)
    end
  end
end


#===============================================================================
# Pokedex UI edits.
#===============================================================================

#-------------------------------------------------------------------------------
# Habitats (Main menu)
#-------------------------------------------------------------------------------
if Settings::POKEDEX_HABITAT_ICONS
  class PokemonPokedex_Scene
    alias enhanced_pbRefresh pbRefresh
    def pbRefresh
      enhanced_pbRefresh
      overlay = @sprites["overlay"].bitmap
      species = @sprites["pokedex"].species
      return if !$player.seen?(species)
      _gender, form, _shiny = $player.pokedex.last_form_seen(species)
      species = GameData::Species.get_species_form(species, form)
      pbDisplayHabitat(species, overlay, 150, 249, (@searchResults) ? 1 : 0)
    end
  end
end

#-------------------------------------------------------------------------------
# Egg Groups, Body Shapes (Entry screen)
#-------------------------------------------------------------------------------
class PokemonPokedexInfo_Scene
  alias enhanced_drawPageInfo drawPageInfo
  def drawPageInfo
    enhanced_drawPageInfo
    return if !$player.owned?(@species)
    overlay = @sprites["overlay"].bitmap
    species_data = GameData::Species.get_species_form(@species, @form)
    pbDisplayEggGroups(species_data, overlay, 148, 204, true) if Settings::POKEDEX_EGG_GROUPS
    pbDisplayBodyShape(species_data, overlay, 170, 154, true) if Settings::POKEDEX_BODY_SHAPES
  end
end


#===============================================================================
# Miscellaneous additions.
#===============================================================================

#-------------------------------------------------------------------------------
# Shiny Leaf Pokemon data.
#-------------------------------------------------------------------------------
class Pokemon
  def shiny_leaf;   return @shiny_leaf || 0; end
  def shiny_crown?; return @shiny_leaf == 6; end
    
  def shiny_leaf?
    return false if @shiny_leaf.nil?
    return @shiny_leaf > 0
  end
  
  def shiny_leaf=(value)
    value = (value < 0) ? 0 : (value > 6) ? 6 : value
    @shiny_leaf = (value)
  end
  
  alias enhanced_initialize initialize  
  def initialize(*args)
    @shiny_leaf = 0
    enhanced_initialize(*args)
  end
end

#-------------------------------------------------------------------------------
# Shiny Leaf debug options.
#-------------------------------------------------------------------------------
MenuHandlers.add(:pokemon_debug_menu, :set_shiny_leaf, {
  "name"   => _INTL("Shiny Leaf"),
  "parent" => :dx_pokemon_menu,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      msg = [_INTL("Has shiny crown."), _INTL("Has shiny leaf x#{pkmn.shiny_leaf}.")][pkmn.shiny_crown? ? 0 : 1]
      cmd = screen.pbShowCommands(msg, [
           _INTL("Set leaf count"),
           _INTL("Set crown"),
           _INTL("Reset")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Set Leaf
        params = ChooseNumberParams.new
        params.setRange(0, 6)
        params.setDefaultValue(pkmn.shiny_leaf)
        leafcount = pbMessageChooseNumber(
          _INTL("Set {1}'s leaf count (max. 6).", pkmn.name), params) { screen.pbUpdate }
        pkmn.shiny_leaf = leafcount
      when 1   # Set Crown
        pkmn.shiny_leaf = 6
      when 2   # Reset
        pkmn.shiny_leaf = 0
      end
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})