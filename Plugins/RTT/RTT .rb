#==============================================================================
#Config	
#Set NoSoftReset to true if you want to set the random teams once per savefile.
#Else it's gonna randomize the teams each time you go into a fight which makes
#it possible to soft reset in front of a trainer to change his/her team.
NoSoftReset = false
#Set FirstGuaranteed to true if you want the first Pokemon in the list to be
#the guaranteed one 2 and more is gonna be downwards from there on.
#Set it to false if you want the last pokemon listed to be the guarantee 2
#and more is gonna be upwards from there on.
FirstGuaranteed = false
#============================================================================== 
module Compiler
  module_function

  def compile_trainers(path = "PBS/trainers.txt")
    compile_pbs_file_message_start(path)
    GameData::Trainer::DATA.clear
    schema = GameData::Trainer::SCHEMA
    max_level = GameData::GrowthRate.max_level
    trainer_names      = []
    trainer_lose_texts = []
    trainer_hash       = nil
    current_pkmn       = nil
    # Read each line of trainers.txt at a time and compile it as a trainer property
    idx = 0
    pbCompilerEachPreppedLine(path) { |line, line_no|
      echo "." if idx % 50 == 0
      idx += 1
      Graphics.update if idx % 250 == 0
      if line[/^\s*\[\s*(.+)\s*\]\s*$/]
        # New section [trainer_type, name] or [trainer_type, name, version]
        if trainer_hash
          if !current_pkmn
            raise _INTL("Started new trainer while previous trainer has no Pokémon.\r\n{1}", FileLineData.linereport)
          end
          # Add trainer's data to records
          trainer_hash[:id] = [trainer_hash[:trainer_type], trainer_hash[:name], trainer_hash[:version]]
          GameData::Trainer.register(trainer_hash)
        end
        line_data = pbGetCsvRecord($~[1], line_no, [0, "esU", :TrainerType])
        # Construct trainer hash
        trainer_hash = {
          :trainer_type => line_data[0],
          :name         => line_data[1],
          :version      => line_data[2] || 0,
          :numpkmn		  => 0,	      #byKota
          :guaranteed	  => false,   #byKota
          :pokemon      => []
        }
        current_pkmn = nil
        trainer_names.push(trainer_hash[:name])
      elsif line[/^\s*(\w+)\s*=\s*(.*)$/]
        # XXX=YYY lines
        if !trainer_hash
          raise _INTL("Expected a section at the beginning of the file.\r\n{1}", FileLineData.linereport)
        end
        property_name = $~[1]
        line_schema = schema[property_name]
        next if !line_schema
        property_value = pbGetCsvRecord($~[2], line_no, line_schema)
        # Error checking in XXX=YYY lines
        case property_name
        when "NumPkmn"    #byKota
          if property_value > 6
              raise _INTL("Bad NumPkmn: {1} (must be 0-6).\r\n{2}", property_value, FileLineData.linereport)
          end  
        when "Pokemon"
          if property_value[1] > max_level
            raise _INTL("Bad level: {1} (must be 1-{2}).\r\n{3}", property_value[1], max_level, FileLineData.linereport)
          end
        when "Name"
          if property_value.length > Pokemon::MAX_NAME_SIZE
            raise _INTL("Bad nickname: {1} (must be 1-{2} characters).\r\n{3}", property_value, Pokemon::MAX_NAME_SIZE, FileLineData.linereport)
          end
        when "Moves"
          property_value.uniq!
        when "IV"
          property_value.each do |iv|
            next if iv <= Pokemon::IV_STAT_LIMIT
            raise _INTL("Bad IV: {1} (must be 0-{2}).\r\n{3}", iv, Pokemon::IV_STAT_LIMIT, FileLineData.linereport)
          end
        when "EV"
          property_value.each do |ev|
            next if ev <= Pokemon::EV_STAT_LIMIT
            raise _INTL("Bad EV: {1} (must be 0-{2}).\r\n{3}", ev, Pokemon::EV_STAT_LIMIT, FileLineData.linereport)
          end
          ev_total = 0
          GameData::Stat.each_main do |s|
            next if s.pbs_order < 0
            ev_total += (property_value[s.pbs_order] || property_value[0])
          end
          if ev_total > Pokemon::EV_LIMIT
            raise _INTL("Total EVs are greater than allowed ({1}).\r\n{2}", Pokemon::EV_LIMIT, FileLineData.linereport)
          end
        when "Happiness"
          if property_value > 255
            raise _INTL("Bad happiness: {1} (must be 0-255).\r\n{2}", property_value, FileLineData.linereport)
          end
        when "Ball"
          if !GameData::Item.get(property_value).is_poke_ball?
            raise _INTL("Value {1} isn't a defined Poké Ball.\r\n{2}", property_value, FileLineData.linereport)
          end
        end
        # Record XXX=YYY setting
        case property_name
        when "Items", "LoseText","NumPkmn", "Guaranteed"	#byKota
          trainer_hash[line_schema[0]] = property_value
          trainer_lose_texts.push(property_value) if property_name == "LoseText"
        when "Pokemon"
          current_pkmn = {
            :species => property_value[0],
            :level   => property_value[1]
          }
          trainer_hash[line_schema[0]].push(current_pkmn)
        else
          if !current_pkmn
            raise _INTL("Pokémon hasn't been defined yet!\r\n{1}", FileLineData.linereport)
          end
          case property_name
          when "IV", "EV"
            value_hash = {}
            GameData::Stat.each_main do |s|
              next if s.pbs_order < 0
              value_hash[s.id] = property_value[s.pbs_order] || property_value[0]
            end
            current_pkmn[line_schema[0]] = value_hash
          else
            current_pkmn[line_schema[0]] = property_value
          end
        end
      end
    }
    # Add last trainer's data to records
    if trainer_hash
      if !current_pkmn
        raise _INTL("End of file reached while last trainer has no Pokémon.\r\n{1}", FileLineData.linereport)
      end
      trainer_hash[:id] = [trainer_hash[:trainer_type], trainer_hash[:name], trainer_hash[:version]]
      GameData::Trainer.register(trainer_hash)
    end
    # Save all data
    GameData::Trainer.save
    MessageTypes.setMessagesAsHash(MessageTypes::TrainerNames, trainer_names)
    MessageTypes.setMessagesAsHash(MessageTypes::TrainerLoseText, trainer_lose_texts)
    process_pbs_file_message_end
  end
end 

if !PluginManager.installed?("Essentials Deluxe")
  module GameData
    class Trainer
      SCHEMA = {
        "Items"        => [:items,           "*e", :Item],
        "LoseText"     => [:lose_text,       "q"],
        "NumPkmn"      => [:numpkmn,         "u"],  #byKota
      "Guaranteed"   => [:guaranteed,      "u"],  #byKota
        "Pokemon"      => [:pokemon,         "ev", :Species],   # Species, level
        "Form"         => [:form,            "u"],
        "Name"         => [:name,            "s"],
        "Moves"        => [:moves,           "*e", :Move],
        "Ability"      => [:ability,         "e", :Ability],
        "AbilityIndex" => [:ability_index,   "u"],
        "Item"         => [:item,            "e", :Item],
        "Gender"       => [:gender,          "e", { "M" => 0, "m" => 0, "Male" => 0, "male" => 0, "0" => 0,
                                                    "F" => 1, "f" => 1, "Female" => 1, "female" => 1, "1" => 1 }],
        "Nature"       => [:nature,          "e", :Nature],
        "IV"           => [:iv,              "uUUUUU"],
        "EV"           => [:ev,              "uUUUUU"],
        "Happiness"    => [:happiness,       "u"],
        "Shiny"        => [:shininess,       "b"],
        "SuperShiny"   => [:super_shininess, "b"],
        "Shadow"       => [:shadowness,      "b"],
        "Ball"         => [:poke_ball,       "e", :Item]
      }

      def initialize(hash)
        @id             = hash[:id]
        @trainer_type   = hash[:trainer_type]
        @real_name      = hash[:name]         || "Unnamed"
        @version        = hash[:version]      || 0
        @items          = hash[:items]        || []
        @real_lose_text = hash[:lose_text]    || "..."
        @numpkmn        = hash[:numpkmn]      || 0    #byKota
        @guara     	    = hash[:guaranteed]   || 0    #byKota	
        @pokemon        = hash[:pokemon]      || []
        @pokemon.each do |pkmn|
          GameData::Stat.each_main do |s|
            pkmn[:iv][s.id] ||= 0 if pkmn[:iv]
            pkmn[:ev][s.id] ||= 0 if pkmn[:ev]
          end
        end
      end

      def to_trainer
        tr_name = self.name
        Settings::RIVAL_NAMES.each do |rival|
          next if rival[0] != @trainer_type || !$game_variables[rival[1]].is_a?(String)
          tr_name = $game_variables[rival[1]]
          break
        end
        trainer = NPCTrainer.new(tr_name, @trainer_type)
        trainer.id        = $player.make_foreign_ID
        trainer.items     = @items.clone
        trainer.lose_text = self.lose_text

        if @numpkmn > 0      #byKota        
          if FirstGuaranteed == true
            pokemon_team2 = @pokemon.shift(@guara)
          else 
            pokemon_team2 = @pokemon.pop(@guara)
          end  
          pokemon_team3 = pokemon_team2.rotate(0)        
          if NoSoftReset == true
            ttype2 = @trainer_type.to_s
            ttype = ttype2.codepoints
            tname = @real_name.codepoints
            playerID = $Trainer.id
            hash = ttype, tname, @version, playerID
            hash.flatten!
            hash = hash.sum
            srand(hash)
          end
          pokemon_team = @pokemon.sample(@numpkmn)
          pokemon_team += pokemon_team2
          if FirstGuaranteed == true
            @pokemon = pokemon_team3.shift(@guara) + @pokemon
          else
            @pokemon = @pokemon + pokemon_team3.pop(@guara)
          end  
        else
          pokemon_team = @pokemon
        end	
        # Create each Pokémon owned by the trainer
        pokemon_team.each do |pkmn_data|    #byKota
          puts pokemon_team
          species = GameData::Species.get(pkmn_data[:species]).species
          pkmn = Pokemon.new(species, pkmn_data[:level], trainer, false)
          trainer.party.push(pkmn)
          if pkmn_data[:form]
            pkmn.forced_form = pkmn_data[:form] if MultipleForms.hasFunction?(species, "getForm")
            pkmn.form_simple = pkmn_data[:form]
          end
          pkmn.item = pkmn_data[:item]
          if pkmn_data[:moves] && pkmn_data[:moves].length > 0
            pkmn_data[:moves].each { |move| pkmn.learn_move(move) }
          else
            pkmn.reset_moves
          end
          pkmn.ability_index = pkmn_data[:ability_index] || 0
          pkmn.ability = pkmn_data[:ability]
          pkmn.gender = pkmn_data[:gender] || ((trainer.male?) ? 0 : 1)
          pkmn.shiny = (pkmn_data[:shininess]) ? true : false
          pkmn.super_shiny = (pkmn_data[:super_shininess]) ? true : false
          if pkmn_data[:nature]
            pkmn.nature = pkmn_data[:nature]
          else
            species_num = GameData::Species.keys.index(species) || 1
            tr_type_num = GameData::TrainerType.keys.index(@trainer_type) || 1
            idx = (species_num + tr_type_num) % GameData::Nature.count
            pkmn.nature = GameData::Nature.get(GameData::Nature.keys[idx]).id
          end
          GameData::Stat.each_main do |s|
            if pkmn_data[:iv]
              pkmn.iv[s.id] = pkmn_data[:iv][s.id]
            else
              pkmn.iv[s.id] = [pkmn_data[:level] / 2, Pokemon::IV_STAT_LIMIT].min
            end
            if pkmn_data[:ev]
              pkmn.ev[s.id] = pkmn_data[:ev][s.id]
            else
              pkmn.ev[s.id] = [pkmn_data[:level] * 3 / 2, Pokemon::EV_LIMIT / 6].min
            end
          end
          pkmn.happiness = pkmn_data[:happiness] if pkmn_data[:happiness]
          pkmn.name = pkmn_data[:name] if pkmn_data[:name] && !pkmn_data[:name].empty?
          #-----------------------------------------------------------------------
          # Sets the default values for plugin properties on trainer's Pokemon.
          #-----------------------------------------------------------------------
          pkmn.ace = (pkmn_data[:trainer_ace]) ? true : false
          if PluginManager.installed?("Focus Meter System")
            pkmn.focus_style = pkmn_data[:focus] || Settings::FOCUS_STYLE_DEFAULT
          end
          if PluginManager.installed?("Pokémon Birthsigns")
            pkmn.birthsign = pkmn_data[:birthsign] || :VOID
          end
          if PluginManager.installed?("ZUD Mechanics")
            pkmn.dynamax_lvl = pkmn_data[:dynamax_lvl]
            pkmn.gmax_factor = (pkmn_data[:gmaxfactor]) ? true : false
          end
          if PluginManager.installed?("Terastal Phenomenon")
            pkmn.tera_type = pkmn_data[:teratype]
          end
          if PluginManager.installed?("PLA Battle Styles")
            pkmn.master_moveset if pkmn_data[:mastery]
          end
          #-----------------------------------------------------------------------
          if pkmn_data[:shadowness]
            pkmn.makeShadow
            pkmn.update_shadow_moves(true)
            pkmn.shiny = false
            #---------------------------------------------------------------------
            # Sets base values for plugin properties on shadow Pokemon.
            #---------------------------------------------------------------------
            if PluginManager.installed?("Focus Meter System")
              pkmn.focus_style = :None
            end
            if PluginManager.installed?("Pokémon Birthsigns")
              pkmn.birthsign = :VOID
            end
            if PluginManager.installed?("ZUD Mechanics")
              pkmn.dynamax_lvl = 0
              pkmn.gmax_factor = false
            end
            if PluginManager.installed?("Terastal Phenomenon")
              pkmn.tera_type = nil
            end
            if PluginManager.installed?("PLA Battle Styles")
              pkmn.moves.each { |m| m.mastered = false }
            end
            #---------------------------------------------------------------------
          end
          pkmn.poke_ball = pkmn_data[:poke_ball] if pkmn_data[:poke_ball]
          pkmn.calc_stats
        end
        return trainer
      end
    end
  end
end
#==============================================================================  