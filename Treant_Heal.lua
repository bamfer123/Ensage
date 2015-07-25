--<<Auto Treant Heal by Rivaillle based on Auto Support by Moones>>

require("libs.ScriptConfig")
require("libs.Utils")

local config = ScriptConfig.new()
config:SetParameter("HealToggle", "G", config.TYPE_HOTKEY)
config:SetParameter("HealOn", true )

config:SetParameter("HealTowerToggle", "H", config.TYPE_HOTKEY)
config:SetParameter("AllowHealTower", true)
config:SetParameter("HealTowerPercent", 0.7)
config:SetParameter("SafeRange", 1500)
config:Load()

setTowerHeal = config.HealTowerToggle
allowHealTower = config.AllowHealTower

safeRange = config.SafeRange
HealthTower = config.HealTowerPercent
healToggle = config.HealToggle
healOn = config.HealOn
allyAtRisk = false
local x,y = 10, 580

local monitor = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F14","Tahoma",14*monitor,550*monitor) 
local status = healOn and "ON" or "OFF"
local statusText = drawMgr:CreateText(x*monitor,y*monitor,-1,"Auto Heal: "..status.." - Hotkey: ''"..string.char(healToggle).."''",F14) statusText.visible = false


function Key(msg, code)
    if msg ~= KEY_UP or client.chat or client.console then return end
	if code == setTowerHeal then
		allowHealTower = not allowHealTower
	elseif code == healToggle then
	    healOn = not healOn
        status = healOn and "ON" or "OFF" 
		statusText.text = "Auto Heal: "..status.." - Hotkey: ''"..string.char(healToggle).."''"
	end
	
end


function Tick(tick)	
	local me = entityList:GetMyHero()	
	if not me then return end
	local ID = me.classId
	if not reg then		
		reg = true
	end
	local allies = entityList:GetEntities({type = LuaEntity.TYPE_HERO,team = me.team})
	local allyToHeal = nil
	local heal = me:GetAbility(3)
	if healOn and SleepCheck("heal") and heal:CanBeCasted() and me:CanCast() and not me:IsChanneling() and me.alive then
		for i,v in ipairs(allies) do
			if v.alive and v.health > 0 and not v:IsIllusion() and (v ~= me) then
			  allyToHeal = compareAlly(v, allyToHeal)
			end
		end
		if allyToHeal then		   
			me:SafeCastAbility(heal, allyToHeal)
			Sleep(1000, "heal")
		  
		elseif allowHealTower and not allyAtRisk then
			local tower = entityList:GetEntities({classId=CDOTA_BaseNPC_Tower,team = me.team,alive=true,visible=true})
			table.sort( tower, function (a,b) return a.health < b.health end )
			lowestHP = tower[1]
			if lowestHP.health/lowestHP.maxHealth < HealthTower then				
				me:CastAbility(heal,lowestHP)
				Sleep(1000, "heal")								
				
			end
		end
	end
    allyAtRisk = false
end

function compareAlly(ally, allyToHeal)
    if allyToHeal then
	     if ally.health < allyToHeal.health and (IsDisabled(ally) or IsInDanger(ally)) then
		    return ally
		 end
	elseif IsDisabled(ally) or IsInDanger(ally) then
	    return ally
	end
	return allyToHeal

end

function IsInDanger(hero)
    local distanceEnemyHero = 9999
	if hero and hero.alive and hero.health > 0 then
		for k,z in ipairs(entityList:GetProjectiles({target=hero})) do		    
		    if z.source and z.source.classId == 323 and z.source.team == hero:GetEnemyTeam() then
			    return true
			end
						
		end	

        local enemy = entityList:GetEntities({type=LuaEntity.TYPE_HERO,alive=true,visible=true,team=hero:GetEnemyTeam(),illusion=false})		
		for i,v in pairs(enemy) do
		    distanceEnemyHero = GetDistance2D(v,hero)
		    if distanceEnemyHero <= safeRange then
			  allyAtRisk = true
			end
			for i,k in pairs(v.abilities) do
				if not lowDamageSkill(k) and k.level > 0 and (k.abilityPhase or (k:CanBeCasted() and k:FindCastPoint() < 0.4)) and distanceEnemyHero <= k.castRange+200 and (((math.max(math.abs(FindAngleR(v) - math.rad(FindAngleBetween(v, hero))) - 0.20, 0)) == 0 
					and (k:IsBehaviourType(LuaEntityAbility.BEHAVIOR_UNIT_TARGET) or k:IsBehaviourType(LuaEntityAbility.BEHAVIOR_POINT))) or k:IsBehaviourType(LuaEntityAbility.BEHAVIOR_NO_TARGET)) then
					return true
				end
			end
		
		end
		
		local modifiers = {"modifier_item_urn_damage","modifier_doom_bringer_doom","modifier_axe_battle_hunger","modifier_queenofpain_shadow_strike","modifier_phoenix_fire_spirit_burn","modifier_venomancer_poison_nova","modifier_venomancer_venomous_gale","modifier_silencer_curse_of_the_silent","modifier_silencer_last_word"}
		for i,v in ipairs(modifiers) do 
			if hero:DoesHaveModifier(v) then
			    print("hero "..hero.name.." is in danger,have modified")
				return true
			end
		end
	end
end

function lowDamageSkill(ability)

  if ability.name == "phantom_assassin_stifling_dagger" then
      return true
  end
  return false
end

function Support(hId)
	if hId == CDOTA_Unit_Hero_Oracle or hId == CDOTA_Unit_Hero_KeeperOfTheLight or hId == CDOTA_Unit_Hero_Dazzle or hId == CDOTA_Unit_Hero_Chen or hId == CDOTA_Unit_Hero_Dazzle or hId == CDOTA_Unit_Hero_Enchantress or hId == CDOTA_Unit_Hero_Legion_Commander or hId == CDOTA_Unit_Hero_Abaddon or hId == CDOTA_Unit_Hero_Omniknight or hId == CDOTA_Unit_Hero_Treant or hId == CDOTA_Unit_Hero_Wisp or hId == CDOTA_Unit_Hero_Centaur or hId == CDOTA_Unit_Hero_Undying or hId == CDOTA_Unit_Hero_WitchDoctor or hId == CDOTA_Unit_Hero_Necrolyte or hId == CDOTA_Unit_Hero_Warlock or hId == CDOTA_Unit_Hero_Rubick or hId == CDOTA_Unit_Hero_Huskar then
		return true
	else
		return false
	end
end

function IsDisabled(unit)
	local stunned = false
	local modifiers_table = {"modifier_shadow_demon_disruption", "modifier_obsidian_destroyer_astral_imprisonment_prison", 
		"modifier_eul_cyclone", "modifier_invoker_tornado", "modifier_bane_nightmare", "modifier_shadow_shaman_shackles", 
		"modifier_crystal_maiden_frostbite", "modifier_ember_spirit_searing_chains", "modifier_axe_berserkers_call",
		"modifier_lone_druid_spirit_bear_entangle_effect", "modifier_meepo_earthbind", "modifier_naga_siren_ensnare",
		"modifier_storm_spirit_electric_vortex_pull", "modifier_treant_overgrowth"}
	local modifiers = unit.modifiers
	for i,m in ipairs(modifiers) do
		for i,k in ipairs(modifiers_table) do
			if m and (m.stunDebuff or m.name == k) then
				stunned = true
			end
		end
	end
	return stunned or unit:IsStunned()
end

function Load()
	if PlayingGame() then
		local me = entityList:GetMyHero()
	    local ID = me.classId
        
		if not me or not ID == CDOTA_Unit_Hero_Treant then
			script:Disable()
		else	
			statusText.visible = true
            script:RegisterEvent(EVENT_KEY, Key)		
			script:RegisterEvent(EVENT_FRAME, Tick)
			script:UnregisterEvent(Load)
		end
	end	
end

function Close()
	if reg then
		script:UnregisterEvent(Tick)
		script:RegisterEvent(EVENT_TICK, Load)	
		script:UnregisterEvent(Key)
		reg = false
	end
end

script:RegisterEvent(EVENT_CLOSE,Close)
script:RegisterEvent(EVENT_TICK,Load)
