--<<Auto Clinkz by Rivaillle based on Auto Armlet Toggle by Sophylax, reworked and updated by Moones>>
require("libs.Utils")
require("libs.ScriptConfig")
require("libs.Animations")
require("libs.HeroInfo")
require("libs.AbilityDamage")
require("libs.TargetFind")

local config = ScriptConfig.new()
config:SetParameter("SetAutoStrafe", "L", config.TYPE_HOTKEY)
config:SetParameter("AutoStrafe", true)
config:Load()

setAutoStrafe = config.SetAutoStrafe
autoStrafe = config.AutoStrafe

function Key(msg, code)
    if msg ~= KEY_UP or client.chat or client.console then return end

	if code == setAutoStrafe then
		autoStrafe = not autoStrafe
	end
end

function Tick( tick )
	if not PlayingGame() or client.console or client.paused then return end
	local me = entityList:GetMyHero()
	player = entityList:GetMyPlayer()
	if not reg then		
		reg = true
	end
	
	local moc = me:FindItem("item_medallion_of_courage")
	local solar = me:FindItem("item_solar_crest")
	local orchid = me:FindItem("item_orchid")
	local closest = targetFind:GetClosestToMouse(me,1000)
	if autoStrafe and me.mana > me.maxMana / 2 then
		castAbility(me, me:GetAbility(1), closest)
    end
	
	if orchid then
        castItem(me, orchid, closest)
	end
	
	if moc then
		castItem(me, moc, closest)
	end
	
	if solar then
		castItem(me, solar, closest)
	end	
	
end

function castItem(me, item, closest)
  if item and item:CanBeCasted() and closest and closest.alive and closest.visible and not me:IsStunned() and not me:IsInvisible() and (player.orderId == Player.ORDER_ATTACKENTITY or player.orderId == Player.ORDER_USEABILITY or player.orderId == Player.ORDER_USEABILITYENTITY ) and  (Animations.CanMove(me) or me:DoesHaveModifier("modifier_clinkz_strafe")) and SleepCheck(item.name)  then
	  me:CastAbility(item, closest)
	  Sleep(500, item.name)
  end
end

function castAbility(me, ability, closest)
  if ability and ability:CanBeCasted() and closest and closest.alive and closest.visible and not me:IsStunned() and not me:IsInvisible() and (player.orderId == Player.ORDER_ATTACKENTITY or player.orderId == Player.ORDER_USEABILITY or player.orderId == Player.ORDER_USEABILITYENTITY )  and SleepCheck(ability.name) then
	  me:CastAbility(ability)
	  Sleep(1000, ability.name)  
  end
end

function Load()
	if PlayingGame() then
		local me = entityList:GetMyHero()
		if not me then 
			script:Disable()
		else	
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

script:RegisterEvent(EVENT_CLOSE, Close)
script:RegisterEvent(EVENT_TICK, Load)