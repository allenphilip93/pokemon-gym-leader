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