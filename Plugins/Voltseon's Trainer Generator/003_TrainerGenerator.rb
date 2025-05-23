######################################
#
# Voltseon's Trainer Generator
#
######################################
# Version 1.1
######################################
#
# Battle Generator
#
######################################
#
# To start generating a battle, call:
# vGenerateTrainer(eventID,items,levels,partySize,nameVar,classVar,genderVar)
#
# Example:
# vGenerateTrainer(5,2,[50,80],[1,2],1,2,3,4)
# This would initiate a random trainer to event #5
# The trainer will have items 2 random items
# They will have between 1 and 2 Pokémon
# Their pokemon will be between level 50 and 80
# Their name, class, gender and event will be pushed to variable 1, 2, 3 and 4 (gender is either 0 or 1)
#
######################################

# Sets the event ID to a random generated trainer
def vGenerateTrainerWEvent(eventID, items=0,levels=[50,50],party_size=[3,6],trainer_group_prob=[1,0,0,0],name_variable=1,class_variable=2,gender_variable=3,event_variable=4)
  # Check for event viability
  return false if eventID.nil? || (!eventID.is_a?(Integer) && !eventID.is_a?(Game_Event))
  # Set the event
  event = nil
  event = get_character(eventID) if !eventID.is_a?(Game_Event)
  # Get a random trainer class
  trainer_class = RT_TRAINER_WHITELIST[rand(0...RT_TRAINER_WHITELIST.length)]
  # Update the trainer type
  trainer_class[0] = GameData::TrainerType.try_get(trainer_class[0])
  # Set trainer's gender
  trainer_gender = trainer_class[0].gender
  # Get a random trainer name based on the arrays
  trainer_name = trainer_gender == 0 ? RT_MALE_NAMES[rand(0...RT_MALE_NAMES.length)] : RT_FEMALE_NAMES[rand(0...RT_FEMALE_NAMES.length)]
  # Try to get a gender neutral name based on chance
  trainer_name = RT_NEUTRAL_NAMES[rand(0...RT_NEUTRAL_NAMES.length)] if rand(100) < GENDER_NEUTRAL_CHANCE
  # Set variables that can be used in common event
  pbSet(name_variable,trainer_name)
  pbSet(class_variable,trainer_class[0].real_name)
  pbSet(gender_variable,trainer_gender)
  pbSet(event_variable,event)
  # Get overworld graphic
  overwold_graphic = trainer_class[1]
  # Checks if overworld graphic exists, otherwise generate one from the trainer class if possible
  if !File.file?(_INTL("Graphics/Characters/{1}.png",overwold_graphic)) && File.file?(_INTL("Graphics/Characters/trainer_{1}.png",trainer_class[0].id))
    overwold_graphic = _INTL("trainer_{1}.png",trainer_class[0].id)
  end
  # Set the event itself
  event.character_name = overwold_graphic
  event.character_hue = 0

  # 
  pbTurnTowardEvent(event,$game_player)
  # Concurrent::Future.execute { get_request }

  # pbMoveRoute(
  #   event,
  #   [
  #     PBMoveRoute::Down,
  #     PBMoveRoute::Down, 
  #     PBMoveRoute::Down,
  #     PBMoveRoute::Down, 
  #     PBMoveRoute::Left
  #   ], 
  #   true)
  pbCommonEvent(RT_COMMON_EVENT_ID)
  return vRandomTrainerBattle(trainer_class,trainer_name,items,levels,party_size, trainer_group_prob)
end

# Sets the event ID to a random generated trainer
def vGenerateTrainer(items=0,levels=[50,50],party_size=[3,6],trainer_group_prob=[1,0,0,0],name_variable=1,class_variable=2,gender_variable=3,event_variable=4)
  # Check for event viability
  # return false if eventID.nil? || (!eventID.is_a?(Integer) && !eventID.is_a?(Game_Event))
  # Set the event
  # event = nil
  # event = get_character(eventID) if !eventID.is_a?(Game_Event)
  # Get a random trainer class
  trainer_class = RT_TRAINER_WHITELIST[rand(0...RT_TRAINER_WHITELIST.length)]
  # Update the trainer type
  trainer_class[0] = GameData::TrainerType.try_get(trainer_class[0])
  # Set trainer's gender
  trainer_gender = trainer_class[0].gender
  # Get a random trainer name based on the arrays
  trainer_name = trainer_gender == 0 ? RT_MALE_NAMES[rand(0...RT_MALE_NAMES.length)] : RT_FEMALE_NAMES[rand(0...RT_FEMALE_NAMES.length)]
  # Try to get a gender neutral name based on chance
  trainer_name = RT_NEUTRAL_NAMES[rand(0...RT_NEUTRAL_NAMES.length)] if rand(100) < GENDER_NEUTRAL_CHANCE
  # Set variables that can be used in common event
  # pbSet(name_variable,trainer_name)
  # pbSet(class_variable,trainer_class[0].real_name)
  # pbSet(gender_variable,trainer_gender)
  # pbSet(event_variable,event)
  # Get overworld graphic
  overwold_graphic = trainer_class[1]
  # Checks if overworld graphic exists, otherwise generate one from the trainer class if possible
  if !File.file?(_INTL("Graphics/Characters/{1}.png",overwold_graphic)) && File.file?(_INTL("Graphics/Characters/trainer_{1}.png",trainer_class[0].id))
    overwold_graphic = _INTL("trainer_{1}.png",trainer_class[0].id)
  end
  # Set the event itself
  # event.character_name = overwold_graphic
  # event.character_hue = 0
  # pbTurnTowardEvent(event,$game_player)
  # pbCommonEvent(RT_COMMON_EVENT_ID)
  return vRandomTrainerBattle(trainer_class,trainer_name,items,levels,party_size)
end

# Generates and initiates a trainer battle
def vRandomTrainerBattle(trainer_class,trainer_name,items,levels,party_size,trainer_group_prob)
  return false if trainer_class.nil? || trainer_name.nil?
  # Get a random lose text
  lose_text = LOSE_TEXTS[rand(0...LOSE_TEXTS.length)]
  # Create trainer object
  trainer = NPCTrainer.new(trainer_name, trainer_class[0])
  trainer.id        = $Trainer.make_foreign_ID
  trainer.items     = []
  trainer.lose_text = lose_text
  # Add random items based on input
  for i in 0...items
    item = ITEM_WHITELIST[rand(0...ITEM_WHITELIST.length)] if items>0
    trainer.items.push(GameData::Item.try_get(item))
  end

  trainer_group = pickRandomTrainerGroup(trainer_group_prob)
  if trainer_group == "legendary"
    party_size = [1,3]
  end
  pbMessage(_INTL("\\bHmm looks like it is a {1} trainer", trainer_group))

  # Create each Pokémon owned by the trainer
  for i in 0...rand(party_size[0]..party_size[1]) # Iterate through a random party size
    # Check if the trainer has any preferred types
    if trainer_class.length > 2
      preferred_types = trainer_class
      preferred_types.drop(2)
    end

    # Get the species based on the preferred types
    species = vGetRandomPreferredSpecies(preferred_types, trainer_group)
    # Set level
    level = rand(levels[0]..levels[1])
    level.round
    # Evolve / unevolve based on paramaters
    old_species = species
    if FORCED_UNEVOLVED_LEVEL > level
      species = species.get_baby_species
      species = species.get_previous_species if species == old_species
    elsif FORCED_FULLY_EVOLVED_LEVEL < level
      evolution_data = species.get_evolutions
      if !evolution_data.nil?
        species = evolution_data[evolution_data.length-1][0] if evolution_data.length>0
      end
    end
    # Create the Pokemon from its species data
    random_pokemon = Pokemon.new(species,level)
    # Push to trainer
    trainer.party.push(random_pokemon)
  end
  #  Auto-scaling to pick up the event
  # EventHandlers.trigger(:on_trainer_load, trainer)
  # Trigger the trainer battle
  TrainerBattle.start_core(trainer)
  return true
end

def pickRandomTrainerGroup(trainer_group_prob=[1,0,0,0])
  trainer_groups = ["weak", "moderate", "strong", "legendary"]
  sample = []
  for i in 0...trainer_group_prob.length
    count = trainer_group_prob[i] * 1000
    count = count.to_int
    sample += Array.new(count, i)
  end
  sample = sample.shuffle()
  trainer_idx = sample[rand(0...sample.length)]
  $game_variables[87] = trainer_idx
  return trainer_groups[trainer_idx]
end

# Checks through all the available pokemon for the preferred type
def vGetRandomPreferredSpecies(preferred_types, trainer_group="weak")
  # Only get all species if using the blacklist
  if USE_SPECIES_BLACKLIST
    # Fill out an species array with all species in the game
    species_arr = []
    GameData::Species.each do |s|
      # Skip pokemon in the blacklist
      next if SPECIES_BLACKLIST.include?(s.id)
      species_arr.push(s.id)
    end
  end

  # Generate any Pokemon if no preferred type is set
  if (preferred_types == [] || preferred_types.nil?)
    if trainer_group == "weak"
      return GameData::Species.try_get(WEAK_SPECIES_WHITELIST[rand(0...WEAK_SPECIES_WHITELIST.length)])
    elsif trainer_group == "moderate"
      return GameData::Species.try_get(MODERATE_SPECIES_WHITELIST[rand(0...MODERATE_SPECIES_WHITELIST.length)])
    elsif trainer_group == "strong"
      return GameData::Species.try_get(STRONG_SPECIES_WHITELIST[rand(0...STRONG_SPECIES_WHITELIST.length)])
    elsif trainer_group == "legendary"
      return GameData::Species.try_get(LEGENDARY_SPECIES_WHITELIST[rand(0...LEGENDARY_SPECIES_WHITELIST.length)])
    else
      return USE_SPECIES_BLACKLIST ? vGetNonBlacklistSpecies(species_arr) : GameData::Species.try_get(SPECIES_WHITELIST[rand(0...SPECIES_WHITELIST.length)])
    end
  end
  # Initializing values
  species = nil
  species_types = []
  species_id = nil
  # Try to get the preferred types / species
  until preferred_types.include?(species_types[0]) || preferred_types.include?(species_types[1]) || preferred_types.include?(species_id)
    if trainer_group == "weak"
      species = GameData::Species.try_get(WEAK_SPECIES_WHITELIST[rand(0...WEAK_SPECIES_WHITELIST.length)])
    elsif trainer_group == "moderate"
      species = GameData::Species.try_get(MODERATE_SPECIES_WHITELIST[rand(0...MODERATE_SPECIES_WHITELIST.length)])
    elsif trainer_group == "strong"
      species = GameData::Species.try_get(STRONG_SPECIES_WHITELIST[rand(0...STRONG_SPECIES_WHITELIST.length)])
    elsif trainer_group == "legendary"
      species = GameData::Species.try_get(LEGENDARY_SPECIES_WHITELIST[rand(0...LEGENDARY_SPECIES_WHITELIST.length)])
    else
      species = USE_SPECIES_BLACKLIST ? vGetNonBlacklistSpecies(species_arr) : GameData::Species.try_get(SPECIES_WHITELIST[rand(0...SPECIES_WHITELIST.length)])
    end
    species_types = species.types
    species_id = species.id
  end
  return species
end

# Get a species that is not from the blacklist
def vGetNonBlacklistSpecies(species_arr)
  # Initializing values
  species = nil
  # Generate a random species
  species = GameData::Species.try_get(species_arr[rand(species_arr.length)])
  # Return the resulting species
  return species
end
# Play both the Last Wish games made by Voltseon and ENLS (1 with NocTurn and 2 with PurpleZaffre)