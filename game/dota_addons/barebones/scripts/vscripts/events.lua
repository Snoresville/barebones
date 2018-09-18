-- This file contains all barebones-registered events and has already set up the passed-in parameters for you to use.

-- Cleanup a player when they leave
function your_gamemode_name:OnDisconnect(keys)
	--DebugPrint('[BAREBONES] Player Disconnected ' .. tostring(keys.userid))
	--PrintTable(keys)

	local name = keys.name
	local networkID = keys.networkid
	local reason = keys.reason
	local userID = keys.userid
end

-- The overall game state has changed
function your_gamemode_name:OnGameRulesStateChange(keys)
	--DebugPrint("[BAREBONES] GameRules State Changed")
	--PrintTable(keys)
	
	local new_state = GameRules:State_Get()
	
	if new_state == DOTA_GAMERULES_STATE_INIT then

	elseif new_state == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then

	elseif new_state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		GameRules:SetCustomGameSetupAutoLaunchDelay(CUSTOM_GAME_SETUP_TIME)
	elseif new_state == DOTA_GAMERULES_STATE_HERO_SELECTION then
		your_gamemode_name:PostLoadPrecache()
		your_gamemode_name:OnAllPlayersLoaded()
		Timers:CreateTimer(HERO_SELECTION_TIME - 1.1, function()
			for playerID = 0, 19 do
				if PlayerResource:IsValidPlayerID(playerID) then
					-- If this player still hasn't picked a hero, random one
					if not PlayerResource:HasSelectedHero(playerID) then
						PlayerResource:GetPlayer(playerID):MakeRandomHeroSelection()
						PlayerResource:SetHasRandomed(playerID)
						PlayerResource:SetCanRepick(playerID, false)
						print("Randomed a hero for a player number "..playerID)
					end
				end
			end
		end)
	elseif new_state == DOTA_GAMERULES_STATE_STRATEGY_TIME then

	elseif new_state == DOTA_GAMERULES_STATE_TEAM_SHOWCASE then

	elseif new_state == DOTA_GAMERULES_STATE_WAIT_FOR_MAP_TO_LOAD then

	elseif new_state == DOTA_GAMERULES_STATE_PRE_GAME then

	elseif new_state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		your_gamemode_name:OnGameInProgress()
	elseif new_state == DOTA_GAMERULES_STATE_POST_GAME then

	elseif new_state == DOTA_GAMERULES_STATE_DISCONNECT then

	end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function your_gamemode_name:OnNPCSpawned(keys)
	--DebugPrint("[BAREBONES] NPC Spawned")
	--PrintTable(keys)
	
	local npc = EntIndexToHScript(keys.entindex)
	local unit_owner = npc:GetOwner()
	
	-- Put things here that will happen for every unit or hero when they spawn
	
	-- OnHeroInGame
	if npc:IsRealHero() and npc.bFirstSpawned == nil then
		npc.bFirstSpawned = true
		your_gamemode_name:OnHeroInGame(npc)
	end
end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function your_gamemode_name:OnEntityHurt(keys)
	--DebugPrint("[BAREBONES] Entity Hurt")
	--PrintTable(keys)
	-- Don't use this unless you know what are you doing
end

-- An item was picked up off the ground
function your_gamemode_name:OnItemPickedUp(keys)
	--DebugPrint( '[BAREBONES] OnItemPickedUp' )
	--PrintTable(keys)

	local unit_entity
	if keys.UnitEntitIndex then
		unit_entity = EntIndexToHScript(keys.UnitEntitIndex)
	elseif keys.HeroEntityIndex then
		unit_entity = EntIndexToHScript(keys.HeroEntityIndex)
	end

	local item_entity = EntIndexToHScript(keys.ItemEntityIndex)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local item_name = keys.itemname
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function your_gamemode_name:OnPlayerReconnect(keys)
	--DebugPrint( '[BAREBONES] OnPlayerReconnect' )
	--PrintTable(keys) 
end

-- An item was purchased by a player
function your_gamemode_name:OnItemPurchased(keys)
	--DebugPrint( '[BAREBONES] OnItemPurchased' )
	--PrintTable(keys)

	-- The playerID of the hero who is buying something
	local playerID = keys.PlayerID
	if not playerID then
		return
	end

	-- The name of the item purchased
	local item_name = keys.itemname 
  
	-- The cost of the item purchased
	local item_cost = keys.itemcost
end

-- An ability was used by a player
function your_gamemode_name:OnAbilityUsed(keys)
	--DebugPrint('[BAREBONES] AbilityUsed')
	--PrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local ability_name = keys.abilityname
	
	-- If you need to adjust cast abilities use Order Filter, not this
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function your_gamemode_name:OnNonPlayerUsedAbility(keys)
	--DebugPrint('[BAREBONES] OnNonPlayerUsedAbility')
	--PrintTable(keys)

	local ability_name = keys.abilityname
	
	-- If you need to adjust cast abilities use Order Filter, not this
end

-- A player changed their name, useless in most cases
function your_gamemode_name:OnPlayerChangedName(keys)
	--DebugPrint('[BAREBONES] OnPlayerChangedName')
	--PrintTable(keys)

	local new_name = keys.newname
	local old_name = keys.oldName
end

-- A player leveled up an ability
function your_gamemode_name:OnPlayerLearnedAbility(keys)
	--DebugPrint('[BAREBONES] OnPlayerLearnedAbility')
	--PrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local ability_name = keys.abilityname
	local playerID = player:GetPlayerID()
	local hero = PlayerResource:GetAssignedHero(playerID)
	
	-- For custom talents
	if ability_name == "special_bonus_unique_hero_name" then
		local talent = hero:FindAbilityByName(ability_name)
		if talent then
			hero:AddNewModifier(hero, talent, "modifier_custom_talent_name", {})
		end
	end
end

-- A channelled ability finished by either completing or being interrupted
function your_gamemode_name:OnAbilityChannelFinished(keys)
	--DebugPrint('[BAREBONES] OnAbilityChannelFinished')
	--PrintTable(keys)

	local ability_name = keys.abilityname
	local interrupted = keys.interrupted == 1
end

-- A player leveled up
function your_gamemode_name:OnPlayerLevelUp(keys)
	--DebugPrint('[BAREBONES] OnPlayerLevelUp')
	--PrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local level = keys.level
	local playerID = player:GetPlayerID()
	
	local hero = PlayerResource:GetAssignedHero(playerID)
	local hero_level = hero:GetLevel()
	local hero_streak = hero:GetStreak()
	
	-- Update Minimum hero gold bounty on level up
	local gold_bounty
	if hero_streak > 2 then
		gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL + (hero_streak-2)*60
	else
		gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL
	end

	hero:SetMinimumGoldBounty(gold_bounty)
	
	-- If you want to remove skill points on level up then uncomment this line:
	--hero:SetAbilityPoints(0)
end

-- A player last hit a creep, a tower, or a hero
function your_gamemode_name:OnLastHit(keys)
	--DebugPrint('[BAREBONES] OnLastHit')
	--PrintTable(keys)

	local IsFirstBlood = keys.FirstBlood == 1
	local IsHeroKill = keys.HeroKill == 1
	local IsTowerKill = keys.TowerKill == 1
	
	-- Player that got a last hit
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	
	-- Killed unit (creep, hero, tower etc.)
	local killed_entity = EntIndexToHScript(keys.EntKilled)
end

-- A tree was cut down by tango, quelling blade, etc
function your_gamemode_name:OnTreeCut(keys)
	--DebugPrint('[BAREBONES] OnTreeCut')
	--PrintTable(keys)
	
	local treeX = keys.tree_x
	local treeY = keys.tree_y
end

-- A rune was activated by a player
function your_gamemode_name:OnRuneActivated(keys)
	--DebugPrint('[BAREBONES] OnRuneActivated')
	--PrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local rune = keys.rune
  
  -- For Bounty Runes use BountyRunePickup Filter
end

-- A player took damage from a tower
function your_gamemode_name:OnPlayerTakeTowerDamage(keys)
	--DebugPrint('[BAREBONES] OnPlayerTakeTowerDamage')
	--PrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local damage = keys.damage
end

-- A player picked a hero
function your_gamemode_name:OnPlayerPickHero(keys)
	--DebugPrint('[BAREBONES] OnPlayerPickHero')
	--PrintTable(keys)

	local hero_name = keys.hero
	local hero_entity = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)
	
	Timers:CreateTimer(0.5, function()
		local playerID = hero_entity:GetPlayerID() -- or player:GetPlayerID()
		if PlayerResource:IsFakeClient(playerID) then
			-- This is happening only for bots when they spawn for the first time or if they use custom hero-create spells (Custom Illusion spells)
		else
			if PlayerResource.PlayerData[playerID].already_assigned_hero == true then
				-- This is happening only when players create new heroes with spells (Custom Illusion spells)
			else
				PlayerResource:AssignHero(playerID, hero_entity)
				PlayerResource.PlayerData[playerID].already_assigned_hero = true
			end
		end
	end)
end

-- A player killed another player in a multi-team context
function your_gamemode_name:OnTeamKillCredit(keys)
	--DebugPrint('[BAREBONES] OnTeamKillCredit')
	--PrintTable(keys)

	local killer_player = PlayerResource:GetPlayer(keys.killer_userid)
	local victim_player = PlayerResource:GetPlayer(keys.victim_userid)
	local streak = keys.herokills
	local killer_team = keys.teamnumber
end

-- An entity died
function your_gamemode_name:OnEntityKilled(keys)
	--DebugPrint( '[BAREBONES] OnEntityKilled Called' )
	--PrintTable(keys)
	
	-- The Unit that was Killed
	local killed_unit = EntIndexToHScript(keys.entindex_killed)
	
	-- The Killing entity
	local killer_unit = nil

	if keys.entindex_attacker ~= nil then
		killer_unit = EntIndexToHScript(keys.entindex_attacker)
	end
	
	-- The ability/item used to kill, or nil if not killed by an item/ability
	local killing_ability = nil

	if keys.entindex_inflictor ~= nil then
		killing_ability = EntIndexToHScript(keys.entindex_inflictor)
	end
	
	-- Killed Unit is a hero (not an illusion) and he is not reincarnating
	if killed_unit:IsRealHero() and (not killed_unit:IsReincarnating()) then
		
		-- Get his killing streak
		local hero_streak = killed_unit:GetStreak()
		-- Get his level
		local hero_level = killed_unit:GetLevel()
	
		-- Adjust Minimum Gold bounty
		local gold_bounty
		if hero_streak > 2 then
			gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL + (hero_streak-2)*60
		else
			gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL
		end
		killed_unit:SetMinimumGoldBounty(gold_bounty)
		
		-- Maximum Respawn Time
		if ENABLE_HERO_RESPAWN then
			local respawnTime = killed_unit:GetRespawnTime()
			if respawnTime > MAX_RESPAWN_TIME then
				--print("Hero has a long respawn time")
				respawnTime = MAX_RESPAWN_TIME
				killed_unit:SetTimeUntilRespawn(respawnTime)
			end
		end
		
		-- Buyback Cooldown
		if CUSTOM_BUYBACK_COOLDOWN_ENABLED then
			PlayerResource:SetCustomBuybackCooldown(killed_unit:GetPlayerID(), BUYBACK_COOLDOWN_TIME)
		end
		
		-- Killer is not a hero but it killed a hero
		if killer_unit:IsTower() or killer_unit:IsCreep() or IsFountain(killer_unit) then

		end
		
		-- When team hero kill limit is reached
		if END_GAME_ON_KILLS and GetTeamHeroKills(killer_unit:GetTeam()) >= KILLS_TO_END_GAME_FOR_TEAM then
			GameRules:SetGameWinner(killer_unit:GetTeam())
		end
		
		if SHOW_KILLS_ON_TOPBAR then
			GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_BADGUYS, GetTeamHeroKills(DOTA_TEAM_BADGUYS))
			GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_GOODGUYS, GetTeamHeroKills(DOTA_TEAM_GOODGUYS))
		end
	end
	
	-- Ancient destruction detection (if the map doesn't have ancients with this names, this will never happen)
	if killed_unit:GetUnitName() == "npc_dota_badguys_fort" then
		GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
	elseif killed_unit:GetUnitName() == "npc_dota_goodguys_fort" then
		GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
	end
	
	-- Remove dead non-hero units from selection -> bugged ability/cast bar
	if killed_unit:IsIllusion() or (killed_unit:IsControllableByAnyPlayer() and (not killed_unit:IsHero()) and (not killed_unit:IsCourier())) then
		local player = killed_unit:GetPlayerOwner()
		local playerID
		if player == nil then
			playerID = killed_unit:GetPlayerOwnerID()
		else
			playerID = player:GetPlayerID()
		end
		PlayerResource:RemoveFromSelection(playerID, killed_unit)
	end
end

-- This function is called 1 to 2 times as the player connects initially but before they have completely connected
function your_gamemode_name:PlayerConnect(keys)
	--DebugPrint('[BAREBONES] PlayerConnect')
	--PrintTable(keys)
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function your_gamemode_name:OnConnectFull(keys)
	--DebugPrint('[BAREBONES] OnConnectFull')
	--PrintTable(keys)
  
	your_gamemode_name:CaptureGameMode()

	local index = keys.index
	local playerID = keys.PlayerID
	local userID = keys.userid
	
	PlayerResource:OnPlayerConnect(keys)
end

-- This function is called whenever illusions are created and tells you which was/is the original entity
function your_gamemode_name:OnIllusionsCreated(keys)
	--DebugPrint('[BAREBONES] OnIllusionsCreated')
	--PrintTable(keys)

	local original_entity = EntIndexToHScript(keys.original_entindex)
end

-- This function is called whenever an item is combined to create a new item
function your_gamemode_name:OnItemCombined(keys)
	--DebugPrint('[BAREBONES] OnItemCombined')
	--PrintTable(keys)

	-- The playerID of the hero who is buying something
	local playerID = keys.PlayerID
	if not playerID then
		return 
	end
	local player = PlayerResource:GetPlayer(playerID)

	-- The name of the item that was combined
	local item_name = keys.itemname 
  
	-- The cost of the item combined
	local item_cost = keys.itemcost
end

-- This function is called whenever an ability begins its PhaseStart phase (but before it is actually cast)
function your_gamemode_name:OnAbilityCastBegins(keys)
	--DebugPrint('[BAREBONES] OnAbilityCastBegins')
	--PrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local ability_name = keys.abilityname
end

-- This function is called whenever a tower is killed
function your_gamemode_name:OnTowerKill(keys)
	--DebugPrint('[BAREBONES] OnTowerKill')
	--PrintTable(keys)

	local gold = keys.gold
	local killer_player = PlayerResource:GetPlayer(keys.killer_userid)
	local team = keys.teamnumber
end

-- This function is called whenever a player changes there custom team selection during Game Setup 
function your_gamemode_name:OnPlayerSelectedCustomTeam(keys)
	--DebugPrint('[BAREBONES] OnPlayerSelectedCustomTeam')
	--PrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.player_id)
	local success = (keys.success == 1)
	local team = keys.team_id
end

-- This function is called whenever an NPC reaches its goal position/target
function your_gamemode_name:OnNPCGoalReached(keys)
	--DebugPrint('[BAREBONES] OnNPCGoalReached')
	--PrintTable(keys)

	local goal_entity = EntIndexToHScript(keys.goal_entindex)
	local next_goal_entity = EntIndexToHScript(keys.next_goal_entindex)
	local npc = EntIndexToHScript(keys.npc_entindex)
end

-- This function is called whenever any player sends a chat message to team or All
function your_gamemode_name:OnPlayerChat(keys)
	--PrintTable(keys)
	
	local team_only = keys.teamonly
	local userID = keys.userid
	local text = keys.text
end
