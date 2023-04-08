#===============================================================================
# Settings
#===============================================================================
module Settings
  #-----------------------------------------------------------------------------
  # Party Ball
  #-----------------------------------------------------------------------------
  # Enables the Party menu display of ball icons that match each Pokemon's ball.
  #-----------------------------------------------------------------------------
  SHOW_PARTY_BALL = true
  
  #-----------------------------------------------------------------------------
  # Happiness Meter
  #-----------------------------------------------------------------------------
  # Enables the display of a happiness meter in the Pokemon's Summary screen.
  #-----------------------------------------------------------------------------
  SUMMARY_HAPPINESS_METER = true
  
  #-----------------------------------------------------------------------------
  # Shiny Leaf
  #-----------------------------------------------------------------------------
  # Enables the display of a Pokemon's collected Shiny Leaves in the Summary/Storage screens.
  #-----------------------------------------------------------------------------
  SUMMARY_SHINY_LEAF = true
  STORAGE_SHINY_LEAF = true
  
  #-----------------------------------------------------------------------------
  # IV Ratings
  #-----------------------------------------------------------------------------
  # Enables the display of ratings for a Pokemon's IV's in the Summary/Storage screens.
  #-----------------------------------------------------------------------------
  SUMMARY_IV_RATINGS = true
  STORAGE_IV_RATINGS = true
  IV_DISPLAY_STYLE   = 0  # 0 = Stars, 1 = Letters
  
  #-----------------------------------------------------------------------------
  # Egg Groups
  #-----------------------------------------------------------------------------
  # Enables the display of icons indicating a Pokemon's Egg Groups in the Summary/Pokedex screens.
  #-----------------------------------------------------------------------------
  SUMMARY_EGG_GROUPS = true
  POKEDEX_EGG_GROUPS = true
  
  #-----------------------------------------------------------------------------
  # Body Shapes
  #-----------------------------------------------------------------------------
  # Enables the display of icons indicating a Pokemon's Body Shape in the Pokedex screen.
  #-----------------------------------------------------------------------------
  POKEDEX_BODY_SHAPES = true
  SHAPE_DISPLAY_STYLE = 0  # 0 = Modern, 1 = Retro
  
  #-----------------------------------------------------------------------------
  # Habitats
  #-----------------------------------------------------------------------------
  # Enables the display of icons indicating a Pokemon's Habitat in the Pokedex menu.
  #-----------------------------------------------------------------------------
  POKEDEX_HABITAT_ICONS = true
  
  #-----------------------------------------------------------------------------
  # Battle UI Windows
  #-----------------------------------------------------------------------------
  # Keys used to toggle the display of in-battle UI windows.
  #-----------------------------------------------------------------------------
  MOVE_INFO_KEY   = :M
  BATTLE_INFO_KEY = :N
  
  #-----------------------------------------------------------------------------
  # Type Displays (Battle UI)
  #-----------------------------------------------------------------------------
  # Toggles whether type displays for unregistered species are shown in battle UI's.
  #-----------------------------------------------------------------------------
  ALWAYS_DISPLAY_TYPES = false
end