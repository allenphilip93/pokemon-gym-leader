#===============================================================================
# Custom utilities
#===============================================================================

def pbCheckBetSuccess
  if $game_variables[97] > 0
    if $game_variables[97] > $game_variables[98]
      pbMessage("\\G\\bManager: Oops didn't meet the requirements boss")
      penalty = 250 * ($game_variables[97] - $game_variables[98])
      pbMessage(_INTL("\\G\\bManager: We have to pay ${1} to the dealer", penalty.to_s_formatted))
      if $player.money > penalty
        $player.money -= penalty
      else
        $player.money = 0
      end
    else
      pbMessage("\\G\\bManager: Good job boss, you're killing it")
      bonus = 500 * ($game_variables[97] - 1)
      $player.money += bonus
      pbMessage(_INTL("\\G\\bManager: We got a bonus of ${1} from the dealer", bonus.to_s_formatted))
    end
  end
end

def pbValidateParty
  favored_type = nil
  case $game_variables[95]
  when 0
    favored_type = :FIRE
  when 1
    favored_type = :WATER
  when 2
    favored_type = :GRASS
  when 3
    favored_type = :BUG
  end
  pbMessage(_INTL("\\bChecking if only {1} type pokemons are present..", favored_type))
  new_party = []
  if favored_type
    $player.party.each do |pkmn|
      new_party.push(pkmn) if pkmn.types.include?(favored_type)
    end
  end
  if new_party.length() == $player.party.length()
    pbMessage(_INTL("\\bLooks good to me boss!"))
    $game_switches[98] = true
  else
    pbMessage(_INTL("\\bSorry boss, team is not valid!"))
    pbMessage(_INTL("\\bYou can use the PC in the back office to move some of the pokemons to the box."))
    $game_switches[98] = false
  end
end

def pbSetValidStreak
  max_streak = $player.money / 250
  $game_variables[96] = max_streak + 1
end

ItemHandlers::UseOnPokemonMaximum.add(:RARECANDY, proc { |item, pkmn|
  if $game_variables[88] == 0
    next GameData::GrowthRate.max_level - pkmn.level
  else
    next $game_variables[88] - pkmn.level
  end
})

ItemHandlers::UseOnPokemon.add(:RARECANDY, proc { |item, qty, pkmn, scene|
  if pkmn.shadowPokemon?
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  if $game_variables[88] == 0
    if pkmn.level >= GameData::GrowthRate.max_level
      new_species = pkmn.check_evolution_on_level_up
      if !Settings::RARE_CANDY_USABLE_AT_MAX_LEVEL || !new_species
        scene.pbDisplay(_INTL("It won't have any effect."))
        next false
      end
      # Check for evolution
      pbFadeOutInWithMusic {
        evo = PokemonEvolutionScene.new
        evo.pbStartScreen(pkmn, new_species)
        evo.pbEvolution
        evo.pbEndScreen
        scene.pbRefresh if scene.is_a?(PokemonPartyScreen)
      }
      next true
    end
  else
    if pkmn.level >= $game_variables[88]
      new_species = pkmn.check_evolution_on_level_up
      if !Settings::RARE_CANDY_USABLE_AT_MAX_LEVEL || !new_species
        scene.pbDisplay(_INTL("It won't have any effect."))
        next false
      end
      # Check for evolution
      pbFadeOutInWithMusic {
        evo = PokemonEvolutionScene.new
        evo.pbStartScreen(pkmn, new_species)
        evo.pbEvolution
        evo.pbEndScreen
        scene.pbRefresh if scene.is_a?(PokemonPartyScreen)
      }
      next true
    end
  end
  # Level up
  pbChangeLevel(pkmn, pkmn.level + qty, scene)
  scene.pbHardRefresh
  next true
})

def generateTrainerForGymDefense
  if $game_variables[94] == 0 # Gym Level
    vGenerateTrainerWEvent(7, 2, [14,16],[1,2])
  elsif $game_variables[94] == 1
    vGenerateTrainerWEvent(7, 2, [24,26],[2,3])
  elsif $game_variables[94] == 2
    vGenerateTrainerWEvent(7, 2, [34,36],[3,4])
  elsif $game_variables[94] == 3
    vGenerateTrainerWEvent(7, 2, [44,46],[4,5])
  elsif $game_variables[94] == 4
    vGenerateTrainerWEvent(7, 2, [54,56],[5,6])
  elsif $game_variables[94] == 5
    vGenerateTrainerWEvent(7, 2, [64,66],[6,6])
  elsif $game_variables[94] == 6
    vGenerateTrainerWEvent(7, 2, [74,76],[6,6])
  elsif $game_variables[94] == 7
    vGenerateTrainerWEvent(7, 2, [84,86],[6,6])
  elsif $game_variables[94] == 8
    vGenerateTrainerWEvent(7, 2, [94,96],[6,6])
  end
end