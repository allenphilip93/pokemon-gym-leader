if PluginManager.installed?("Randomized Trainer Teams")
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
        "Ball"         => [:poke_ball,       "e", :Item],
        "Ace"          => [:trainer_ace, "b"],
        "Focus"        => [:focus,       "u"],
        "Birthsign"    => [:birthsign,   "u"],
        "DynamaxLvl"   => [:dynamax_lvl, "u"],
        "Gigantamax"   => [:gmaxfactor,  "b"],
        "Mastery"      => [:mastery,     "b"],
        "TeraType"     => [:teratype,    "u"]
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