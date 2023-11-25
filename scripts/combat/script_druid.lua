script_druid = {
	message = 'Druid',
	menuIncluded = include("scripts\\combat\\script_druidEX.lua"),
	eatHealth = 35,
	drinkMana = 50,
	rejuvenationMana = 18,	-- use rejuvenation above this mana
	rejuvenationHealth = 80,	-- use rejuvenation below this health
	regrowthHealth = 70,
	healingTouchHealth = 45,
	healthToShift = 55,
	potionHealth = 18,
	potionMana = 20,
	isSetup = false,
	meleeDistance = 3.9,
	waitTimer = 0,
	stopIfMHBroken = true,
	useCat = false,	-- is cat form selected
	useBear = false,	-- is bear form selected
	isChecked = true,
	useEntanglingRoots = true,
	waitTimer = GetTimeEX(),
	useStealth = true,
	stealthOpener = "Ravage",
	shiftToDrink = true,
	useCharge = true,
	useRest = true,
	maulRage = 15,
	wasInCombat = false,
	runOnce = false,
	shapeshiftMana = 33,
}


-- switch to bear form when in cat form
-- adds >= 2 and when 1 dies switch back to cat form
-- add conditional to main phases ' don't do this when x is true '
-- if targets in combat = 2 then x = true else y
-- mana > 50 % else stay in bear form
-- switch when health is low and already out of form to heal then choose bear form over cat form
-- stun target if we switch back to cat form - or return maul and waste all rage
-- TELL CAT FORM TO ONLY BE USED WHEN <= 2 ADDS PROBABLY EASIEST SOLUTION


function script_druid:setup()

	local isBear = GetLocalPlayer():HasBuff("Bear Form");
	local isCat = GetLocalPlayer():HasBuff("Cat Form");
	local isMoonkin = GetLocalPlayer():HasBuff("Moonkin Form");
	if (GetLocalPlayer():GetLevel() >= 40) then
		isBear = GetLocalPlayer():HasBuff("Dire Bear Form");
	end

	-- set entangle roots on startup
	if (not HasSpell("Entangling Roots")) then
		self.useEntanglingRoots = false;
	end

	if (HasSpell("Bear Form")) and (not HasSpell("Cat Form")) then
		self.meleeDistance = 4.80;
	end

	if (not HasSpell("Ravage")) or (not HasSpell("Pounce")) then
		self.stealthOpener = "Shred";
	end
	if (not HasSpell("Shred")) then
		self.stealthOpener = "Claw";
	end

	if (not HasSpell("Prowl")) then
		useStealth = false;
	end
	
	if (not HasSpell("Bear Form")) then
		shiftToDrink = false;
		useCharge = false;
		useRest = false;
	end

	if (HasSpell("Feral Charge")) or (GetLocalPlayer():GetLevel() >= 15) then
		self.maulRage = 10;
	end

	if (GetLocalPlayer():GetLevel() >= 20) then
		self.shapeshiftMana = 25;
	end

	if (GetLocalPlayer():GetLevel() >= 10) and (not HasSpell("Cat Form")) then
		self.useBear = true;
	end
	if (GetLocalPlayer():GetLevel() >= 20) and (HasSpell("Cat Form")) then
		self.useBear = false;
		self.useCat = true;
	end

	if (not HasSpell("Regrowth")) and (HasSpell("Bear Form")) then
		self.healingTouchHealth = 60;
	end

	self.waitTimer = GetTimeEX();	

	self.isSetup = true;
end

function script_druid:enemiesAttackingUs(range) -- returns number of enemies attacking us within range
    local unitsAttackingUs = 0; 
    local currentObj, typeObj = GetFirstObject(); 
    while currentObj ~= 0 do 
    	if typeObj == 3 then
			if (currentObj:CanAttack() and not currentObj:IsDead()) then
				if (script_grind:isTargetingMe(currentObj) and currentObj:GetDistance() <= range) then 
					unitsAttackingUs = unitsAttackingUs + 1; 
				end 
			end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return unitsAttackingUs;
end

-- Run backwards if the target is within range
function script_druid:runBackwards(targetObj, range) 
	local localObj = GetLocalPlayer();
 	if targetObj ~= 0 and (not script_checkDebuffs:hasDisabledMovement()) then
 		local xT, yT, zT = targetObj:GetPosition();
 		local xP, yP, zP = localObj:GetPosition();
 		local distance = targetObj:GetDistance();
 		local xV, yV, zV = xP - xT, yP - yT, zP - zT;	
 		local vectorLength = math.sqrt(xV^2 + yV^2 + zV^2);
 		local xUV, yUV, zUV = (1/vectorLength)*xV, (1/vectorLength)*yV, (1/vectorLength)*zV;	
 		local moveX, moveY, moveZ = xT + xUV*16, yT + yUV*16, zT + zUV;		
 		if (distance < range and targetObj:IsInLineOfSight()) then 
			script_nav:moveToTarget(localObj, moveX, moveY, moveZ);
			if (IsMoving()) then
				JumpOrAscendStart();
			end
 			return true;
 		end
	end
	return false;
end

function script_druid:draw()
	--script_druid:window();
	local tX, tY, onScreen = WorldToScreen(GetLocalPlayer():GetPosition());
	if (onScreen) then
		DrawText(self.message, tX+75, tY+40, 0, 255, 255);
	else
		DrawText(self.message, 25, 185, 0, 255, 255);
	end
end

--[[ error codes: 	0 - All Good , 
			1 - missing arg , 
			2 - invalid target , 
			3 - not in range, 
			4 - do nothing , 
			5 - targeted player pet/totem
			6 - stop bot request from combat script  ]]--




function script_druid:healsAndBuffs()

	local localHealth = GetLocalPlayer():GetHealthPercentage();
	local localMana = GetLocalPlayer():GetManaPercentage();
	local localRage = GetLocalPlayer():GetRagePercentage();
	local localObj = GetLocalPlayer();
	local isBear = GetLocalPlayer():HasBuff("Bear Form");
	local isCat = GetLocalPlayer():HasBuff("Cat Form");
	if (GetLocalPlayer():GetLevel() >= 40) then
		isBear = GetLocalPlayer():HasBuff("Dire Bear Form");
	end
	local hasRejuv = GetLocalPlayer():HasBuff("Rejuvenation"); 
	local hasRegrowth = GetLocalPlayer():HasBuff("Regrowth");

	if (not script_grind.adjustTickRate) then
		script_grind.tickRate = 1500;
	end

--------------

	-- shapeshift out of bear form to heal
	if ( (isBear) and (localHealth <= self.healthToShift) and (localMana >= self.shapeshiftMana) and (not hasRejuv) and (not hasRegrowth) and (script_grind.enemiesAttackingUs(12) < 2) )
	or ( (isBear) and (localHealth <= self.healthToShift) and (localMana >= self.shapeshiftMana + 5) and (not hasRejuv) and (not hasRegrowth) and (script_grind.enemiesAttackingUs(12) >= 2) )then
		if (not script_grind.adjustTickRate) then
			script_grind.tickRate = 135;
			script_rotation.tickRate = 135;
		end
		if (localObj:HasBuff("Dire Bear Form")) then
			CastSpellByName("Dire Bear Form");
			self.waitTimer = GetTimeEX() + 1200;
		end
		if (localObj:HasBuff("Bear Form")) then
			CastSpellByName("Bear Form", localObj);
			self.waitTimer = GetTimeEX() + 1200;
		end
		
	end


	-- shapeshift out of cat form to heal
	if (isCat) and (localHealth <= self.healthToShift) and (localMana >= self.shapeshiftMana) and (not hasRejuv) and (not hasRegrowth) then
		if (not script_grind.adjustTickRate) then
			script_grind.tickRate = 135;
			script_rotation.tickRate = 135;
		end
		if (localObj:HasBuff("Cat Form")) then
			CastSpellByName("Cat Form");
			self.waitTimer = GetTimeEX() + 700;
		end
	end



----------------------

	-- heal 2 or more enemies higher health
	if (script_grind:enemiesAttackingUs(12) >= 2) and (not isBear) and (not isCat) and (localHealth <= self.healthToShift + 20) then

		-- Regrowth
		if (HasSpell("Regrowth")) and (not localObj:HasBuff("Regrowth")) and (localHealth <= self.regrowthHealth + 20) and (localMana >= 35) then
			if (CastHeal("Regrowth", localObj)) then
				self.waitTimer = GetTimeEX() + 3500;
				return 0;
			end
		end

		-- Healing Touch
		if (HasSpell("Healing Touch")) then
			if (localHealth <= self.healingTouchHealth + 10) and (localMana > 25) then
				if (CastHeal("Healing Touch", localObj)) then
					self.waitTimer = GetTimeEX() + 2700;
					return 0;
				end
			end
		end

		-- Rejuvenation
		if (HasSpell("Rejuvenation")) and (not localObj:HasBuff("Rejuvenation")) and (localHealth <= self.rejuvenationHealth) and (localMana >= 10) then
			if (CastSpellByName("Rejuvenation", localObj)) then
				self.waitTimer = GetTimeEX() + 1600;
				return 0;
			end
		end
	end

------------------------------------

	-- shapeshift if has rejuv and regrowth and mana is high enough and health is low enough
	if (self.useBear and isBear) and (localHealth <= self.healthToShift - 35) and (localMana >= 65) and (hasRejuv) and (hasRegrowth) then
		if (not script_grind.adjustTickRate) then
			script_grind.tickRate = 135;
			script_rotation.tickRate = 135;
		end
		if (localObj:HasBuff("Dire Bear Form")) then
			CastSpellByName("Dire Bear Form");
			self.waitTimer = GetTimeEX() + 500;
		end
		if (localObj:HasBuff("Bear Form")) then
			CastSpellByName("Bear Form", localObj);
			self.waitTimer = GetTimeEX() + 500;
		end
		
	end

	-- shapeshift out of cat form to heal - already have rejuve and regrowth
	if (self.useCat and isCat) and (localHealth <= self.healthToShift - 25) and (localMana >= 65) and (hasRejuv) and (hasRegrowth) then
		if (not script_grind.adjustTickRate) then	
			script_grind.tickRate = 135;
			script_rotation.tickRate = 135;
		end
		if (localObj:HasBuff("Cat Form")) then
			CastSpellByName("Cat Form");
			self.waitTimer = GetTimeEX() + 500;
		end
	end


------------------------

	local isBear = GetLocalPlayer():HasBuff("Bear Form");
	local isCat = GetLocalPlayer():HasBuff("Cat Form");

	-- moving buffs hierarchy up
	if (not isBear) and (not isCat) and (IsStanding()) and (not IsEating()) and (not IsDrinking()) and (not IsLooting()) and (script_grind.lootObj == 0 or script_grind.lootObj == nil) then

		-- Mark of the Wild
		if (not IsInCombat()) and (localMana > 75) and (HasSpell("Mark of the Wild")) then
			if (not localObj:HasBuff("Mark of the Wild")) then
				if (CastSpellByName("Mark of the Wild", localObj)) then
					self.waitTimer = GetTimeEX() + 2500;
					return 0;
				end
			end
		end
	
		-- Thorns
		if (localMana > 30) and (HasSpell("Thorns")) and (not localObj:HasBuff("Thorns")) then
			if (localHealth >= self.healthToShift) then
				if (CastSpellByName("Thorns", localObj)) then
					self.waitTimer = GetTimeEX() + 2550;
					return 0;
				end
			end
		end
	end


	-- if not isBear and not isCat
	if (not isBear) and (not isCat) and (IsStanding()) and (not IsEating()) and (not IsDrinking()) and (not IsLooting()) and (script_grind.lootObj == 0 or script_grind.lootObj == nil) then

	-- Regrowth
		if (HasSpell("Regrowth")) and (not localObj:HasBuff("Regrowth")) and (localHealth <= self.regrowthHealth) and (localMana >= 40) and (not IsMoving()) and (not IsLooting()) then
			if (CastHeal("Regrowth", localObj)) then
				self.waitTimer = GetTimeEX() + 3750;
				return 0;
			end
		end

		-- Rejuvenation
		if (HasSpell("Rejuvenation")) and (not localObj:HasBuff("Rejuvenation")) and (localHealth <= self.rejuvenationHealth) and (localMana >= self.rejuvenationMana) and (not IsLooting()) then
			if (CastSpellByName("Rejuvenation", localObj)) then
				self.waitTimer = GetTimeEX() + 1600;
				return 0;
			end
		end
		
		-- Healing Touch
		if (HasSpell("Healing Touch")) and (not IsLooting()) then
			if (localHealth < self.healingTouchHealth) and (localMana > 25) then
				if (CastHeal("Healing Touch", localObj)) then
					self.waitTimer = GetTimeEX() + 2700;
					return 0;
				end
			end
		end

		if (localObj:HasBuff("Regrowth")) and (not localObj:HasBuff("Rejuvenation")) and (localMana >= 15) then
			if (CastSpellByName("Rejuvenation", targetObj)) then
				self.waitTimer = GetTimeEX() + 3750;
				return 0;
			end
		end

		if (localObj:HasBuff("Rejuvenation")) and (not localObj:HasBuff("Regrowth")) and (localMana >= 40) then
			if (CastSpellByName("Regrowth", localObj)) then
				self.waitTimer = GetTimeEX() + 3750;
			end
		end

		-- cure poison
		if (not HasSpell("Abolish Poison")) and (HasSpell("Cure Poison")) and (script_checkDebuffs:hasPoison()) and (localMana >= 45) then
			if (CastSpellByName("Cure Poison", localObj)) then 
				self.waitTimer = GetTimeEX() + 1750; 
				return 0; 
			end
		elseif (HasSpell("Abolish Poison")) and (not localObj:HasBuff("Abolish Poison")) and (script_checkDebuffs:hasPoison()) and (localMana >= 45) then
			if (CastSpellByName("Abolish Poison", targetObj)) then
				self.waitTimer = GetTimeEX() + 1750;
				return 0;
			end
		end

		-- remove curse
		if (HasSpell("Remove Curse")) and (script_checkDebuffs:hasCurse()) then
			if (localMana >= 30) then
				if (CastSpellByName("Remove Curse", localObj)) then
					self.waitTimer = GetTimeEX() + 1750;
					return 0;
				end
			end
		end

		-- Check: Use Healing Potion 
		if (localHealth < self.potionHealth) then 
			if (script_helper:useHealthPotion()) then 
				return 0; 
			end 
		end

		-- Check: Use Mana Potion 
		if (localMana < self.potionMana) then 
			if (script_helper:useManaPotion()) then 
				return 0; 
			end 
		end
	end

--------------------------




	-- set tick rate for script to run
	if (not script_grind.adjustTickRate) then

		local tickRandom = random(550, 950);

		if (IsMoving()) or (not IsInCombat()) then
			script_grind.tickRate = 135;
		elseif (not IsInCombat()) and (not IsMoving()) then
			script_grind.tickRate = tickRandom
		elseif (IsInCombat()) and (not IsMoving()) then
			script_grind.tickRate = tickRandom;
		end
	end
			
return false;
end

function script_druid:run(targetGUID)
	
	if(not self.isSetup) then
		script_druid:setup();
	end
	
	local localObj = GetLocalPlayer();
	local localHealth = localObj:GetHealthPercentage();
	local localMana = localObj:GetManaPercentage();
	local localLevel = localObj:GetLevel();
	local localRage = GetLocalPlayer():GetRagePercentage();
	local localEnergy = GetLocalPlayer():GetEnergyPercentage();
	local localCP = GetComboPoints("player", "target");

	local isBear = GetLocalPlayer():HasBuff("Bear Form");
	local isCat = GetLocalPlayer():HasBuff("Cat Form");
	if (GetLocalPlayer():GetLevel() >= 40) then
		isBear = GetLocalPlayer():HasBuff("Dire Bear Form");
	end

	-- set tick rate for script to run
	if (not script_grind.adjustTickRate) then

		local tickRandom = random(550, 950);

		if (IsMoving()) or (not IsInCombat()) then
			script_grind.tickRate = 135;
		elseif (not IsInCombat()) and (not IsMoving()) then
			script_grind.tickRate = tickRandom
		elseif (IsInCombat()) and (not IsMoving()) then
			script_grind.tickRate = tickRandom;
		end
	end

	if (localObj:IsDead()) then
		return 0; 
	end

	if (script_druid:healsAndBuffs()) and (script_grind.lootObj == nil) then
		return;
	end

	-- Assign the target 
	targetObj = GetGUIDObject(targetGUID);

-- stay in form bear if bear form is selected
		if (self.useBear) or ( script_grind.enemiesAttackingUs(12) >= 2 and HasSpell("Bear Form") and (not IsDrinking()) and (not IsEating()) )
		or ( targetObj:GetLevel() > localObj:GetLevel() + 2 and HasSpell("Bear Form") and (not IsDrinking()) and (not IsEating()) ) then
			if (not isBear) and (not isCat) and (localMana > self.shapeshiftMana) and (localHealth >= self.healthToShift + 5) and (IsStanding()) then
				if (not script_grind.adjustTickRate) then
					script_grind.tickRate = 135;
					script_rotation.tickRate = 135;
				end
				if (HasSpell("Dire Bear Form")) then
					CastSpellByName("Dire Bear Form", localObj);
					self.waitTimer = GetTimeEX() + 1650;
					return 0;
				end
				if (HasSpell("Bear Form")) then
					CastSpellByName("Bear Form", localObj);
					self.waitTimer = GetTimeEX() + 1650;
					return 0;
				end
			end
		end
	
	-- stay in form cat if cat form is selected -- cast cat form
	if (script_grind.enemiesAttackingUs(12) < 2) and (HasSpell("Cat Form")) and (self.useCat) and (not isCat) and (not self.useBear) and (not isBear) and (localMana > self.shapeshiftMana) and (localHealth > self.healthToShift + 5) and (IsStanding()) and (not IsDrinking()) and (not IsEating()) then
		if (not script_grind.adjustTickRate) then
			script_grind.tickRate = 135;
			script_rotation.tickRate = 135;
		end
		CastSpellByName("Cat Form");
		return 0;
	end
	
	if(targetObj == 0 or targetObj == nil) then
		return 2;
	end

	-- Check: Do nothing if we are channeling or casting or wait timer
	if (IsChanneling() or IsCasting() or (self.waitTimer > GetTimeEX())) then
		return 4;
	end

	-- use prowl before spamming auto attack and move in range of target!
	if (not IsInCombat()) and (self.useCat) and (isCat) and (self.useStealth) and (HasSpell("Prowl")) and (not IsSpellOnCD("Prowl")) and (not localObj:HasBuff("Prowl")) and (script_grind.lootObj == nil or script_grind.lootObj == 0) and (not script_checkDebuffs:hasPoison()) and (IsStanding()) then
		CastSpellByName("Prowl");
		return 0;
	end

	--Valid Enemy
	if (targetObj ~= 0) and (not localObj:IsStunned()) then
		
		-- Cant Attack dead targets
		if (targetObj:IsDead() or not targetObj:CanAttack()) then
			return 0;
		end

		-- stand up if sitting
		if (not IsStanding()) then
			JumpOrAscendStart();
		end
	
		if (not IsMoving() and targetObj:GetDistance() <= self.meleeDistance) then
				targetObj:FaceTarget();
		end

		-- 
		if (localMana < self.drinkMana) and (not IsInCombat()) and (GetLocalPlayer():GetLevel() < 10) then
			self.waitTimer = GetTimeEX() + 2500;
			return 4;
		end

		-- assign target health
		targetHealth = targetObj:GetHealthPercentage();

	-- shapeshift out of cat form to use bear form 2 or more targets - leave form

		if (self.useCat) and (isCat) and (localMana >= self.shapeshiftMana) and (localHealth <= self.healthToShift) and (GetNumPartyMembers() < 2) then
			if (script_grind:enemiesAttackingUs(12) >= 2) or (targetObj:GetLevel() > GetLocalPlayer():GetLevel() + 2) then
		
				if (not script_grind.adjustTickRate) then
					script_grind.tickRate = 50;
					script_rotation.tickRate = 50;
				end
				if (localObj:HasBuff("Cat Form")) then
					if (CastSpellByName("Cat Form")) then
						DEFAULT_CHAT_FRAME:AddMessage(" --- Shifted - attacked by adds");
						self.wasInCombat = true;
						self.runOnce = true;
						self.waitTimer = GetTimeEX() + 500;
					end
				end
			end
		end

		-- stay in form - placed here to allow faster movement and stealth to target
		-- not in cat form and conditions right then stay in cat form
		if (script_grind.enemiesAttackingUs(12) < 2) and (not isCat) and (self.useCat) and (not self.useBear) and (not isBear) and (localHealth >= self.healthToShift) and (localMana >= self.shapeshiftMana) and (IsStanding()) and (targetObj:GetLevel() < (GetLocalPlayer():GetLevel() + 2)) and (not IsDrinking()) and (not IsEating()) then
			if (HasSpell("Cat Form")) then
				CastSpellByName("Cat Form");
				return 0;
			end
		end


		-- Check: if we target player pets/totems
		if (GetTarget() ~= nil and targetObj ~= nil) then
			if (UnitPlayerControlled("target") and GetTarget() ~= localObj) then 
				script_grind:addTargetToBlacklist(targetObj:GetGUID());
				return 5; 
			end
		end 

		-- War Stomp Tauren Racial
		if (not isBear) and (not isCat) and (IsInCombat()) then
			if (targetObj:IsCasting() or script_druid:enemiesAttackingUs(6) >= 2) and (GetNumPartyMembers() < 2) and (not targetObj:HasDebuff("Entangling Roots")) and (targetObj:GetDistance() <= 8) then
				if (HasSpell("War Stomp")) and (not IsSpellOnCD("War Stomp")) and (not IsMoving()) then
					CastSpellByName("War Stomp", localObj);
					self.waitTimer = GetTimeEX() + 200;
					return 0;
				end
			end
		end

		-- if out of form use faerie fire
		if (IsInCombat()) and (not isBear) and (not isCat) and (targetObj:GetHealthPercentage() > 20) and (not targetObj:IsDead()) and (localMana > 50) and (not targetObj:HasDebuff("Faerie Fire")) and (HasSpell("Faerie Fire")) then
			CastSpellByName("Faerie Fire", targetObj);
			self.waitTimer = GetTimeEX() + 1750;
			return 0;
		end	

		if (script_druid:healsAndBuffs()) and (script_grind.lootObj == nil) then
			return;
		end

		if (IsInCombat()) and (GetLocalPlayer():GetUnitsTarget() == 0) then
			self.message = "Waiting! Stuck in combat phase!";
			return 4;
		end
		
		----------
		----- OPENER 
		---------

		-- Opener
		if (not IsInCombat()) then
			self.message = "Pulling " .. targetObj:GetUnitName() .. "...";

			if (isCat) and (self.useCat) and (self.useStealth) and (localObj:HasBuff("Prowl")) then
				if (HasSpell(self.stealthOpener)) and (not IsSpellOnCD(self.stealthOpener)) and (localEnergy >= 50) and (targetObj:GetDistance() <= 6) then
					if (CastSpellByName(self.stealthOpener)) then
						self.waitTimer = GetTimeEX() + 300;
						return 0;
					end
				end
			end

			-- Auto Attack
			if (targetObj:GetDistance() < 35) and (not IsAutoCasting("Attack")) and (localMana >= self.drinkMana) then
				targetObj:AutoAttack();
			end

			-- use dash if stealthed
			if (HasSpell("Dash")) and (isCat) and (not IsSpellOnCD("Dash")) and (targetObj:GetDistance() >= 20) and (localObj:HasBuff("Prowl")) then
				if (CastSpellByName("Dash", localObj)) then
					self.waitTimer = GetTimeEX() + 300;
					return 0;
				end
			end

			-- enrage if has charge
			if (isBear) and (HasSpell("Feral Charge")) and (HasSpell("Enrage")) and (not IsSpellOnCD("Enrage")) and (not IsSpellOnCD("Feral Charge")) and (GetLocalPlayer():GetUnitsTarget() ~= 0) then
				if (targetObj:GetDistance() <= 50) then
					CastSpellByName("Enrage", localObj);
					self.waitTimer = GetTimeEX() + 750;
					return 0;
				elseif (HasSpell("Bear Form")) then
					return 3;
				end
			end

			-- use charge in bear form
			if (isBear) and (self.useCharge) and (HasSpell("Feral Charge")) and (not IsSpellOnCD("Feral Charge")) and (localRage >= 5) then
				if (self.useBear) and (isBear) and (targetObj:GetDistance() < 26) and (targetObj:GetDistance() > 10) then
					CastSpellByName("Feral Charge");
					return 4;
				end
			end

			if (isBear or isCat) and (targetObj:GetDistance() > self.meleeDistance) then
				return 3;
			end

			-- move to enemy target
			if (not self.useBear) and (not self.useCat) and (not isBear) and (not isCat) and (targetObj:GetDistance() > 27) and (localMana >= self.drinkMana) then
				return 3;
			end

			-- Dismount
			if (IsMounted()) and (targetObj:GetDistance() < 25) then 
				DisMount(); 
				return 4; 
			end

			if (not IsInCombat()) and (targetObj:GetDistance() <= self.meleeDistance) then
				if (IsMoving()) then
					StopMoving();
				end
					targetObj:FaceTarget();
					self.waitTimer = GetTimeEX() + 800;
			end

			----
	-- pull in form
			----




	-- pull bear form
			------

			-- stay in form
			-- not in bear form and conditions right then stay in bear form
		if ( (not isBear) and (self.useBear) and (not isCat) and (localHealth > self.healthToShift + 5) and (localMana > self.shapeshiftMana)
			and (IsStanding()) and (not IsDrinking()) and (not IsEating()) )
		or ( (script_grind.enemiesAttackingUs(12) >= 2) and (not isBear) and (not isCat) and (localMana > self.shapeshiftMana) and (localHealth > self.healthToShift + 5) and (IsStanding()) and (HasSpell("Bear Form")) ) 
		or ( (targetObj:GetLevel() > (GetLocalPlayer():GetLevel() + 2)) and (not isBear) and (not isCat) and (localMana > self.shapeshiftMana) and (localHealth > self.healthToShift + 5) and (IsStanding()) and (HasSpell("Bear Form")) )
		then
			if (HasSpell("Dire Bear Form")) then
				CastSpellByName("Dire Bear Form");
				self.waitTimer = GetTimeEX() + 1500;
				return 0;
			end
			if (HasSpell("Bear Form")) then
				CastSpellByName("Bear Form", localObj);
				self.waitTimer = GetTimeEX() + 1500;
				return 0;
			end
		end
		
		-- if in bear form do these pulls
		if (isBear) and (not isCat) then

			-- faerie fire
			if (HasSpell("Faerie Fire (Feral)")) and (not targetObj:HasDebuff("Faerie Fire")) and (targetObj:GetDistance() <= 20) and (targetObj:IsInLineOfSight()) then
				if Cast("Faerie Fire (Feral)", targetObj) then
					self.waitTimer = GetTimeEX() + 1500;
					return 0;
				end
			end

			-- Enrage
			if (HasSpell("Enrage")) and (not IsSpellOnCD("Enrage")) and (targetObj:GetDistance() < 30) and (localHealth > self.healthToShift + 25) then
				if (CastSpellByName("Enrage")) then
					return 0;
				end
			end

			-- Demoralizing Roar
			if (HasSpell("Demoralizing Roar")) and (not targetObj:HasBuff("Demoralizing Roar")) and (localRage > 10) and (not targetObj:HasDebuff("Demoralizing Shout")) then
				if (CastSpellByName("Demoralizing Roar")) then
					return 0;
				end
			end
		end


	-- end of bear form pulling




	-- pull cat form
			------

		-- stay in form
		-- not in cat form and conditions right then stay in cat form
		if (script_grind.enemiesAttackingUs(12) < 2) and (not isCat) and (self.useCat) and (not self.useBear) and (not isBear) and (localHealth >= self.healthToShift) and (localMana >= self.shapeshiftMana) and (IsStanding()) and (targetObj:GetLevel() < (GetLocalPlayer():GetLevel() + 2)) and (not IsDrinking()) and (not IsDrinking()) then
			if (HasSpell("Cat Form")) then
				CastSpellByName("Cat Form");
				return 0;
			end
		end

		-- if in cat form do these pulls	
		if (isCat) and (not isBear) then

			if (targetObj:GetDistance() <= self.meleeDistance + 2) then
				targetObj:FaceTarget();
			end
		

			-- faerie fire
			if (not self.useStealth) and (HasSpell("Faerie Fire (Feral)")) and (not targetObj:HasDebuff("Faerie Fire")) then
				if Cast("Faerie Fire (Feral)", targetObj) then
					self.waitTimer = GetTimeEX() + 1000;
					return 0;
				end
			end

			if (HasSpell("Tiger's Fury")) and (not localObj:HasBuff("Tiger's Fury")) and (not IsSpellOnCD("Tiger's Fury")) and (localEnergy >= 30) then
				if (CastSpellByName("Tiger's Fury")) then
					self.waitTimer = GetTimeEX() + 1550;
					return 0;
				end
			end

			if (targetObj:GetDistance() > self.meleeDistance) and (isCat) then
				return 3;
			end
	
		end


	-- end of cat form pulling



			----
	-- pull no form
	-- or level less than 10
			----

		if (not isBear) and (not isCat) then

			-- move into line of sight
			if (targetObj:GetDistance() > 28) or (not targetObj:IsInLineOfSight()) and (localMana >= self.drinkMana) then
				return 3;
			end

			if (targetObj:GetDistance() <= 30) and (not IsMoving()) then
				targetObj:FaceTarget();
			end

			--pull with starfire
			if (HasSpell("Starfire")) and (localMana >= self.drinkMana) then
				if (CastSpellByName("Starfire", targetObj)) then
					targetObj:FaceTarget();
					return 0;
				end
			end

			-- Wrath to pull if no moonfire spell
			if (not HasSpell("Moonfire")) and (localMana >= self.drinkMana) and (not IsMoving()) and (targetObj:GetDistance() <= 30) then
				if (CastSpellByName("Wrath", targetObj)) then
					targetObj:FaceTarget();
					self.waitTimer = GetTimeEX() + 1650;
					self.message = "Casting Wrath!";
					return 0; -- keep trying until cast
				end
			end
			
			-- use moonfire to pull if has spell
			if (HasSpell("Moonfire")) and (localMana >= self.drinkMana) and (not targetObj:HasDebuff("Moonfire")) then
				if (CastSpellByName("Moonfire", targetObj)) then
					self.waitTimer = GetTimeEX() + 1650;
					targetObj:FaceTarget();
					return 0;
				end
			end
			
			-- Entangling roots when target is far enough away and we have enough mana
			if (not self.useBear) and (not self.useCat) and (self.useEntanglingRoots) and (not IsInCombat()) and (not IsMoving()) and (localMana >= self.drinkMana) and (not targetObj:IsCasting()) then
				if (HasSpell("Entangling Roots")) and (not targetObj:HasDebuff("Entangling Roots")) then
					if (Cast("Entangling Roots", targetObj)) then
						self.waitTimer = GetTimeEX() + 1650;
						return 0;
					end
				end
			end
		end

	-- end of pulling not in combat phase


	-- Combat -- start of combat phase! in combat!

	-- IN COMBAT

	-- IN COMBAT




		else	

			self.message = "Killing " .. targetObj:GetUnitName() .. "...";


			if (script_druid:healsAndBuffs()) and (not IsLooting()) then
				return;
			end

	-- attacks in bear form IN COMBAT PHASE

			local isBear = GetLocalPlayer():HasBuff("Bear Form");
			local isCat = GetLocalPlayer():HasBuff("Cat Form");

			-- stay in form
			if ( (self.useBear) and (not isBear) and (not isCat) and (localHealth > self.healthToShift + 5)
				and (localMana >= self.shapeshiftMana) and (IsStanding()) )
			or ( (script_grind.enemiesAttackingUs(12) >= 2) and (not isBear) and (localMana >= self.shapeshiftMana)
				and (not isCat) and (localHealth > self.healthToShift + 5) and (IsStanding()) and (HasSpell("Bear Form")) )
			or ( (targetObj:GetLevel() > (GetLocalPlayer():GetLevel() + 2)) and (not isBear) and (localMana >= self.shapeshiftMana)
				and (not isCat) and (localHealth > self.healthToShift + 5) and (IsStanding()) and (HasSpell("Bear Form")) )

			then
				if (not script_grind.adjustTickRate) then
					script_grind.tickRate = 100;
					script_rotation.tickRate = 100;
				end
				if (GetLocalPlayer():GetLevel() >= 40) then
					CastSpellByName("Dire Bear Form");
					self.waitTimer = GetTimeEX() + 1500;
					return 0;
				end
				if (GetLocalPlayer():GetLevel() < 40) then
					CastSpellByName("Bear Form", localObj);
					self.waitTimer = GetTimeEX() + 1500;
					return 0;
				end
			end
			
			-- shift for debuff removal self use bear form
			if (isBear or not IsBear) and (not isCat and not self.useCat) and (script_checkDebuffs:hasDisabledMovement()) and (localMana >= self.shapeshiftMana*2) and (localHealth > self.healthToShift + 20) and (script_grind.enemiesAttackingUs(12) < 2) then
				if (not script_grind.adjustTickRate) then
					DEFAULT_CHAT_FRAME:AddMessage(" --- Shifted out of form to remove disabled movement debuff!");
					script_grind.tickRate = 100;
					script_rotation.tickRate = 100;
				end
				if (GetLocalPlayer():GetLevel() >= 40) then
					CastSpellByName("Dire Bear Form");
					self.waitTimer = GetTimeEX() + 1500;
					return 0;
				end
				if (GetLocalPlayer():GetLevel() < 40) then
					CastSpellByName("Bear Form", localObj);
					self.waitTimer = GetTimeEX() + 1500;
					return 0;
				end
			end

			-- shift for debuff removal self use cat form
			if (isCat or not isCat) and (not isBear and not self.useBear) and (script_checkDebuffs:hasDisabledMovement()) and (localMana >= self.shapeshiftMana*2) and (localHealth > self.healthToShift + 20) then
				if (not script_grind.adjustTickRate) then
					DEFAULT_CHAT_FRAME:AddMessage(" --- Shifted out of form to remove disabled movement debuff!");
					script_grind.tickRate = 100;
					script_rotation.tickRate = 100;
				end
				if (HasSpell("Cat Form")) then
					CastSpellByName("Cat Form");
					self.waitTimer = GetTimeEX() + 1500;
					return 0;
				end
			end


			-- do these attacks only in bear form
			if (isBear) and (not isCat) then

				if (self.wasInCombat) and (self.runOnce) then
					script_grind.tickRate = 50;
					script_rotation.tickRate = 50;
					self.runOnce = false;
				end

				if (targetObj:GetDistance() <= self.meleeDistance) then
					targetObj:FaceTarget();
				end

				if (not targetObj:IsInLineOfSight()) and (isBear) then
					return 3;
				end
				
				if (targetObj:GetDistance() <= self.meleeDistance + 2) and (not IsMoving()) then
					targetObj:FaceTarget();
				end

				if (IsMoving()) then
					local randomJumpBear = random(1, 100);
					if (randomJumpBear >= 90) then
						JumpOrAscendStart();
					end
				end

				-- Run backwards if we are too close to the target
				if (targetObj:GetDistance() <= .3) then 
					if (script_druid:runBackwards(targetObj,1)) then 
						return 4; 
					end 
				end

				-- keep auto attack on
				if (not IsAutoCasting("Attack")) then
					targetObj:AutoAttack();
					if (targetObj:GetDistance() <= self.meleeDistance) and (not IsMoving()) then
						targetObj:FaceTarget();
					end
				end

				-- back away from enemy if charge is not on CD and use charge in combat??

				-- use charge in bear form
				if (self.useCharge) and (HasSpell("Feral Charge")) and (not IsSpellOnCD("Feral Charge")) and (localRage >= 5) then
					if (self.useBear) and (isBear) and (targetObj:GetDistance() < 26) and (targetObj:GetDistance() > 10) then
						CastSpellByName("Feral Charge");
						return 4;
					end
				end

				-- growl in group
				if (GetNumPartyMembers() >= 2) and (not targetObj:IsTargetingMe()) and (targetObj:GetDistance() <= 10) then
					if (not IsSpellOnCD("Growl")) then
						CastSpellByName("Growl", targetObj);
						self.waitTimer = GetTimeEX() + 800;
						return 0;
					end
				end

				-- bash
				if (HasSpell("Bash")) and (not IsSpellOnCD("Bash")) and (localRage >= 10) and (targetObj:GetDistance() <= self.meleeDistance) and (targetHealth >= 15) then
					if (targetObj:IsCasting()) or (localHealth <= self.healthToShift + 15) then
						CastSpellByName("Bash");
						return;
					end
				end

				-- frenzied regeneration
				if (HasSpell("Frenzied Regeneration")) and (not IsSpellOnCD("Frenzied Regeneration")) and (localhealth < self.healthToShift + 15) and (localRage >= 15) and (localMana < 40) then
					if (CastSpellByName("Frenzied Regeneration")) then
						self.waitTimer = GetTimeEX() + 1000;
					end
				end

				-- keep faerie fire up
				if (HasSpell("Faerie Fire (Feral)")) and (not targetObj:HasDebuff("Faerie Fire (Feral)")) and (not IsSpellOnCD("Faerie Fire (Feral)")) then
					if (Cast("Faerie Fire (Feral)", targetObj)) then
						return 0;
					end
				end

				-- Enrage
				if (HasSpell("Enrage")) and (not IsSpellOnCD("Enrage")) and (targetObj:GetDistance() < 30) and (localHealth > 65) and (targetHealth >= 40) then
					if (CastSpellByName("Enrage")) then
						return 0;
					end
				end

				-- demo Roar
				if (HasSpell("Demoralizing Roar")) and (not targetObj:HasDebuff("Demoralizing Roar")) and (localRage > 10) then
					if (CastSpellByName("Demoralizing Roar")) then
						return 0;
					end
				end

				-- Swipe
				if (script_druid:enemiesAttackingUs(10) >= 2) and (not localObj:HasBuff("Frenzied Regeneration")) then
					if (HasSpell("Swipe")) and (not targetObj:HasDebuff("Swipe")) and (localRage > 15) then
						if (CastSpellByName("Swipe")) then
							return 0;
						end
					end
				end

				-- maul non humanoids
				if (HasSpell("Maul")) and (not IsCasting()) and (not IsChanneling())and (not IsMoving()) and (targetObj:GetCreatureType() ~= 'Humanoid') and (targetObj:GetDistance() <= self.meleeDistance) and (not localObj:HasBuff("Frenzied Regeneration")) and ( (script_grind.enemiesAttackingUs(12) >= 2 and localRage >= 20) or (script_grind.enemiesAttackingUs < 2 and localRage >= self.maulRage) ) then
						targetObj:FaceTarget();
					if (CastSpellByName("Maul", targetObj)) then
						targetObj:AutoAttack();
						targetObj:FaceTarget();
						self.waitTimer = GetTimeEX() + 200;
						return 0;
					end
				
				end

				-- IsFleeing() causes bot not to move
				-- maul humanoids fleeing causes maul to lock up
				if (HasSpell("Maul")) and (not IsCasting()) and (not IsChanneling()) and (not IsMoving())
					and (targetObj:GetCreatureType() == 'Humanoid') and (targetHealth > 30)
					and (targetObj:GetDistance() <= self.meleeDistance) and (not localObj:HasBuff("Frenzied Regeneration"))
						and ( (script_grind.enemiesAttackingUs(12) >= 2 and localRage >= 20 and HasSpell("Swipe"))
						or (script_grind.enemiesAttackingUs < 2 and localRage >= self.maulRage)
						or (script_grind.enemiesAttackingUs >= 2 and not HasSpell("Swipe") and localRage >= self.maulRage) )
				then
						targetObj:FaceTarget();
					if (CastSpellByName("Maul", targetObj)) then
						targetObj:AutoAttack();
						targetObj:FaceTarget();
						self.waitTimer = GetTimeEX() + 200;
						return 0;
					end
				
				end

				if (targetObj:GetDistance() <= self.meleeDistance) and (isBear) then
					targetObj:FaceTarget();
				end

			end -- end of bear form in combat attacks



	-- attacks in cat form IN COMBAT PHASE

			-- shift for debuff removal
			if (self.useCat) and (isCat or not isCat) and (script_checkDebuffs:hasDisabledMovement()) and (localMana >= self.shapeshiftMana*2) and (localHealth > self.healthToShift + 20) then
				if (not script_grind.adjustTickRate) then
					DEFAULT_CHAT_FRAME:AddMessage(" --- Shifted out of form to remove movement disabled debuff!");
					script_grind.tickRate = 100;
					script_rotation.tickRate = 100;
				end
				if (isCat) or (not IsCat) then
					CastSpellByName("Cat Form");
					self.waitTimer = GetTimeEX() + 1500;
					return 0;
				end
			end

			--stay in form
			if (script_grind.enemiesAttackingUs(12) < 2) and (self.useCat and not isCat) and (not self.useBear and not isBear) and (localHealth >= self.healthToShift) and (localMana >= self.shapeshiftMana) and (IsStanding()) and (targetObj:GetLevel() < (GetLocalPlayer():GetLevel() + 2)) then	
				if (not script_grind.adjustTickRate) then
					script_grind.tickRate = 100;
					script_rotation.tickRate = 100;
				end
				CastSpellByName("Cat Form");
			end

			-- do these attacks only in cat form
			if (isCat) and (not isBear) then

				if (targetObj:GetDistance() > self.meleeDistance) and (isCat) then
					script_grind.tickRate = 50;
					script_rotation.tickRate = 50;
					return 3;
				end

				-- Run backwards if we are too close to the target
				if (targetObj:GetDistance() <= .5) then 
					if (script_druid:runBackwards(targetObj,2)) then 
						return 4; 
					end 
				end

				-- keep auto attack on
				if (not IsAutoCasting("Attack")) then
					targetObj:AutoAttack();
					if (not IsMoving()) then
						targetObj:FaceTarget();
					end
				end

				if (targetObj:GetDistance() <= self.meleeDistance) then
					targetObj:FaceTarget();
				end

				-- keep faerie fire up
				if (HasSpell("Faerie Fire (Feral)")) and (not targetObj:HasDebuff("Faerie Fire (Feral)")) and (not IsSpellOnCD("Faerie Fire (Feral)")) then
					if (Cast("Faerie Fire (Feral)", targetObj)) then
						self.waitTimer = GetTimeEX() + 1600;
						return 0;
					end
				end
				
				-- keep tiger's fury up
				if (HasSpell("Tiger's Fury")) and (not localObj:HasBuff("Tiger's Fury")) and (not IsSpellOnCD("Tiger's Fury")) and (localEnergy >= 30) then
					if (CastSpellByName("Tiger's Fury")) then
						self.waitTimer = GetTimeEX() + 1600;
						return 0;
					end
				end

				-- keep rake up
				if (HasSpell("Rake")) and (not targetObj:HasDebuff("Rake")) and (targetHealth >= 30) and (localEnergy >= 35) then
					if (CastSpellByName("Rake", targetObj)) then
						self.waitTimer = GetTimeEX() + 2200;
						return 0;
					end
				end

				-- rip if we are about to shapeshift to heal
				if (localCP >= 2) and (localHealth <= self.healthToShift + 25) and (localEnergy >= 35) and (not HasSpell("Ferocious Bite")) and (not targetObj:HasDebuff("Rip"))then
					if (CastSpellByName("Rip", targetObj)) then
						self.waitTimer = GetTimeEX() + 1250;
						return 0;
					end
				end

				-- Ferocious Bite with 5 CPs
				if (localCP > 4) and (localEnergy >= 35) and (HasSpell("Ferocious Bite")) then
					if (CastSpellByName("Ferocious Bite", targetObj)) then
						self.waitTimer = GetTimeEX() + 1600;
						return 0;
					end
				end

				-- Rip with 5 CPs
				if (localCP > 4) and (localEnergy >= 30) and (not HasSpell("Ferocious Bite")) and (not targetObj:HasDebuff("Rip")) then
					if (CastSpellByName("Rip", targetObj)) then
						self.waitTimer = GetTimeEX() + 1600;
						return 0;
					end
				end

				-- Rip with 3 CPs
				if (localCP >= 3) and (targetHealth <= 50) and (localEnergy >= 30) and (not HasSpell("Ferocious Bite")) and (not targetObj:HasDebuff("Rip")) then
					if (CastSpellByName("Rip", targetObj)) then
						self.waitTimer = GetTimeEX() + 1600;
						return 0;
					end
				end
			
				-- Dynamic health check when using Ferocious Bite between 1 and 4 CP
				if (targetHealth <= (10*localCP)) and (localEnergy >= 35) and (HasSpell("Ferocious Bite")) then
					if (CastSpellByName("Ferocious Bite", targetObj)) then
						self.waitTimer = GetTimeEX() + 1600;
						return 0;
					end
				end

				-- Use Claw
				if (localCP < 5) and (localEnergy >= 40) then
					if (CastSpellByName("Claw")) then
						targetObj:FaceTarget();
						self.waitTimer = GetTimeEX() + 1600;
						return 0;
					end
				end
			end



	-- attacks when not in form

		-- no bear form or cat form

			if (not isBear) and (not isCat) then

				if (targetObj:GetDistance() < 30) and (not IsMoving()) then
					targetObj:FaceTarget();
				end
			
				-- Run backwards if we are too close to the target
				if (targetObj:GetDistance() <= .5) then 
					if (script_druid:runBackwards(targetObj,2)) then 
						return 4; 
					end 
				end

				-- Check: Move backwards if the target is affected by Entangling Root
				if (self.useEntanglingRoots) and (not self.useBear) and (not self.useCat) then
					if (not targetObj:HasDebuff("Entangling Roots")) and (not localObj:HasDebuff("Web")) and (not localObj:HasDebuff("Encasing Webs")) and (localMana > 65) and (targetHealth >= 35) then
						if (not script_grind.adjustTickRate) then
							script_grind.tickRate = 100;
							script_rotation.tickRate = 100;
						end
						if (not targetObj:HasDebuff("Entangling Roots")) and (not targetObj:IsCasting()) then
							if (CastSpellByName("Entangling Roots")) then
								self.waitTimer = GetTimeEX() + 300;
								return 4;
							end
						end
					end 
				end	

				if (targetObj:HasDebuff("Entangling Roots")) and (localMana > 36) then
					if (script_druid:runBackwards(targetObj, 12)) then
						self.waitTimer = GetTimeEX() + 500;
					return 4;
					end
				end

				if (script_druid:healsAndBuffs()) and (not IsLooting()) then
					return;
				end

				-- War Stomp Tauren Racial
				if (HasSpell("War Stomp")) and (not IsSpellOnCD("War Stomp")) and (targetObj:IsCasting() or script_druid:enemiesAttackingUs(10) >= 2) and (not IsMoving()) and (targetObj:GetDistance() <= 8) then
					CastSpellByName("War Stomp");
					self.waitTimer = GetTimeEX() + 200;
					return 0;
				end

				-- keep moonfire up
				if (localMana > 30) and (targetHealth > 5) and (not targetObj:HasDebuff("Moonfire")) and (HasSpell("Moonfire")) then
					if (Cast("Moonfire", targetObj)) then
						self.waitTimer = GetTimeEX() + 1650;
						targetObj:FaceTarget();
						return 0;
					end
				end

				-- spam moonfire until target is killed
				if (localMana > 30) and (targetHealth < 10) and (not IsSpellOnCD("Moonfire")) and (HasSpell("Moonfire")) then
					if (Cast("Moonfire", targetObj)) then
						self.waitTimer = GetTimeEX() + 1650;
						targetObj:FaceTarget();
						return 0;
					end
				end

				-- starfire
				if (HasSpell("Starfire")) and (localMana > 60) and (script_grind:enemiesAttackingUs(10) < 2) and (not IsMoving()) then
					if (CastSpellByName("Starfire", targetObj)) then
						targetObj:FaceTarget();
						self.waitTimer = GetTimeEX() + 800;
					end
				end

				-- Wrath
				if (localMana > 30) and (targetHealth > 15) then
					if (Cast("Wrath", targetObj)) then
						self.waitTimer = GetTimeEX() + 1650;
						targetObj:FaceTarget();
						return 0;
					end
				end	

			end -- end of if not bear or cat... no form attacks
			
			if (targetObj:IsFleeing()) and (not script_grind.adjustTickRate) then
				script_grind.tickRate = 50;
			end

			-- auto attack condition for melee
			if (localMana <= 30 or self.useBear or self.useCat) then
				if (targetObj:GetDistance() <= self.meleeDistance) then
					if (not IsMoving()) then
						targetObj:FaceTarget();
					end
					targetObj:AutoAttack();
				else
					script_grind.tickRate = 50;
					return 3;
				end
			end
		end -- end of else combat phase
	end -- end valid target
end -- end of function

function script_druid:rest()
	if(not self.isSetup) then
		script_druid:setup();
	end

	local localObj = GetLocalPlayer();

	local localLevel = localObj:GetLevel();

	local localHealth = localObj:GetHealthPercentage();

	local localMana = localObj:GetManaPercentage();

	local isBear = GetLocalPlayer():HasBuff("Bear Form");

	local isCat = GetLocalPlayer():HasBuff("Cat Form");

	if (GetLocalPlayer():GetLevel() >= 40) then
		isBear = GetLocalPlayer():HasBuff("Dire Bear Form");
	end


	-- set tick rate for script to run
	if (not script_grind.adjustTickRate) then

		local tickRandom = random(550, 950);

		if (IsMoving()) or (not IsInCombat()) then
			script_grind.tickRate = 135;
		elseif (not IsInCombat()) and (not IsMoving()) then
			script_grind.tickRate = tickRandom
		elseif (IsInCombat()) and (not IsMoving()) then
			script_grind.tickRate = tickRandom;
		end
	end

	-- shapeshift into cat form after bear form
	if (not IsInCombat()) and (isBear) and (self.useCat) and (not IsDrinking()) and (not IsEating()) and (localMana >= self.shapeshiftMana) then
		if (GetLocalPlayer():GetLevel() < 40) then
			CastSpellByName("Bear Form");
			self.wasInCombat = false;

		end
		if (GetLocalPlayer():GetLevel() >= 40) then
			CastSpellByName("Dire Bear Form");
			self.wasInCombat = false;
		end
	end

	-- shift for debuff removal
	if (self.useCat) and (isCat or not isCat) and (script_checkDebuffs:hasDisabledMovement()) and (localMana >= self.shapeshiftMana*2) and (localHealth > self.healthToShift + 20) then
		if (not script_grind.adjustTickRate) then
			DEFAULT_CHAT_FRAME:AddMessage(" --- Shifted out of form to remove movement disabled debuff!");
			script_grind.tickRate = 100;
			script_rotation.tickRate = 100;
		end
		if (isCat) or (not IsCat) then
			CastSpellByName("Cat Form");
			self.waitTimer = GetTimeEX() + 1500;
			return 0;
		end
	end

	-- shift for debuff removal
	if (isBear or not IsBear) and (HasSpell("Bear Form")) and (script_checkDebuffs:hasDisabledMovement()) and (localMana >= self.shapeshiftMana*2) and (localHealth > self.healthToShift + 20) then
		if (not script_grind.adjustTickRate) then
			DEFAULT_CHAT_FRAME:AddMessage(" --- Shifted out of form to remove movement disabled debuff!");
			script_grind.tickRate = 100;
			script_rotation.tickRate = 100;
		end
		if (GetLocalPlayer():GetLevel() >= 40) then
			CastSpellByName("Dire Bear Form");
			self.waitTimer = GetTimeEX() + 1500;
			return 0;
		end
		if (GetLocalPlayer():GetLevel() < 40) then
			CastSpellByName("Bear Form", localObj);
			self.waitTimer = GetTimeEX() + 1500;
			return 0;
		end
	end

	-- shift to drink bear
	if (self.shiftToDrink) and (localMana <= self.drinkMana - 20) and (isBear) and (not IsInCombat()) then
		if (isBear) and (CastSpellByName("Bear Form")) then
			self.waitTimer = GetTimeEX() + 1650;
			return 0;
		end
	end

	-- shift to drink cat
	if (self.shiftToDrink) and (localMana <= self.drinkMana - 20) and (isCat) and (not IsInCombat()) then
		if (isCat) and (CastSpellByName("Cat Form")) then
			self.waitTimer = GetTimeEX() + 1650;
			return 0;
		end
	end

	-- Drink something
	if (not isBear) and (not isCat) and (not IsInCombat()) and (not IsDrinking()) and (localMana <= self.drinkMana) then
		
			self.message = "Need to drink...";
			self.waitTimer = GetTimeEX() + 2850;

	
			-- Dismount
			if(IsMounted()) then 
				DisMount(); 
				return true; 
			end
			if (IsMoving()) then
				StopMoving();
				return true;
			end

			if (script_helper:drinkWater()) and (not IsInCombat()) then 
				ClearTarget();
				self.message = "Drinking..."; 
				self.waitTimer = GetTimeEX() + 2500;
				return true; 
			else 
				self.message = "No drinks! (or drink not included in script_helper)";
				return true; 
			end
		end
	
	-- eat
	if (not isBear) and (not isCat) and (not IsInCombat()) and (not IsEating() and localHealth < self.eatHealth) then

			self.message = "Need to eat...";	
			self.waitTimer = GetTimeEX() + 2850;

			-- Dismount
			if(IsMounted()) then
				DisMount();
			end
			if (IsMoving()) then
				StopMoving();
				return true;
			end
			
			if (script_helper:eat()) and (not IsInCombat()) then 
				self.message = "Eating..."; 
				self.waitTimer = GetTimeEX() + 1500;
				return true; 
			else 
				self.message = "No food! (or food not included in script_helper)";
				self.waitTimer = GetTimeEX() + 1200;
				return true; 
			end	
		end

	if(localMana < self.drinkMana or localHealth < self.eatHealth) then
		if (IsMoving()) then
			StopMoving();
			self.waitTimer = GetTimeEX() + 500;
		end
		return true;
	end

	if (IsEating()) or (IsDrinking()) and (not IsStanding()) and (HasSpell("Shadowmeld")) and (not IsSpellOnCD("Shadowmeld")) and (not isCat) and (not isBear) then
		if (CastSpellByName("Shadowmeld")) then
			self.waitTimer = GetTimeEX() + 2000;
			return 0;
		end
	end

	-- Continue resting
	if(localHealth < 98 and IsEating() or localMana < 98 and IsDrinking()) then
		self.message = "Resting up to full HP/Mana...";
		return true;
	end
		
	-- Stand up if we are rested
	if (localHealth > 98 and (IsEating() or not IsStanding()) 
	    and localMana > 98 and (IsDrinking() or not IsStanding())) then
		StopMoving();
		return false;
	end


	if (script_druid:healsAndBuffs()) and (not IsLooting()) and (script_grind.lootObj == nil) and (not IsDrinking()) and (not IsEating()) then
			self.waitTimer = GetTimeEX() + 500;
		return;
	end
	
	if (self.useRest) and (isCat) and (HasSpell("Prowl")) and (not IsSpellOnCD("Prowl")) and (not localObj:HasBuff("Prowl")) then
		if (GetLocalPlayer():GetUnitsTarget() == 0) and (not script_checkDebuffs:hasPoison()) and (script_grind.lootObj == nil or script_grind.lootObj == 0) and (IsStanding()) then
			if (localMana <= 55 or localHealth <= 55) and (not IsInCombat()) then
				CastSpellByName("Prowl", localObj);
				self.waitTimer = GetTimeEX() + 1000;
			end
		end
	end		

	-- rest in form
	if (isBear or isCat) and (self.useRest) and (script_grind.lootObj == nil) then
		if (GetLocalPlayer():GetUnitsTarget() == 0) then
			if (localMana <= 55 or localHealth <= 55) and (not IsInCombat()) then
				self.message = "Waiting - low mana or health and shapeshifted! Change heal/drink!";
				return;
			end
		end		
	end

	-- Don't need to rest
	return false;
end

function script_druid:window()

	if (self.isChecked) then
	
		--Close existing Window
		EndWindow();

		if(NewWindow("Class Combat Options", 200, 200)) then
			script_druidEX:menu();
		end
	end
end
