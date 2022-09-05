script_follow = {

	renewMana = 25,
	partyRenewHealth = 85,
	shieldMana = 35,
	partyShieldHealth = 55,
	lesserHealMana = 5,
	partyLesserHealHealth = 75,
	healMana = 35,
	partyHealHealth = 50,
	greaterHealMana = 20,
	partyGreaterHealHealth = 30,
	flashHealMana = 7,
	partyFlashHealHealth = 70,
   	holyLightMana = 25,
	partyHolyLightHealth = 60,
	flashOfLightMana = 3,
	partyFlashOfLightHealth = 83,
	layOnHandsHealth = 6,
	bopHealth = 10,
   	healingTouchMana = 35,
    	regrowthMana = 25,
   	rejuvenationMana = 15,
    	healingTouchHealth = 35,
   	regrowthHealth = 60,
   	rejuvenationHealth = 75,
	clickRenew = true,
	clickShield = true,
	clickFlashHeal = true,
	clickGreaterHeal = true,
	clickHeal = true,
	clickHealingTouch = true,
	clickRegrowth = true,
	clickFlashOfLight = true,
	clickHolyLight = true,
	useMount = false,
	disMountRange = 32,
	mountTimer = 0,
	enemyObj = nil,
	lootObj = nil,
	timer = GetTimeEX(),
	tickRate = 150,
	waitTimer = GetTimeEX(),
	pullDistance = 150,
	findLootDistance = 60,
	lootDistance = 2.5,
	skipLooting = true,
	lootCheck = {},
	ressDistance = 25,
	combatError = 0,
	dpsHP = 95,
	myX = 0,
	myY = 0,
	myZ = 0,
	myTime = GetTimeEX(),
	nextToNodeDist = 3,
	isSetup = false,
	drawUnits = false,
	acceptTimer = GetTimeEX(),
	followLeaderDistance = 26,
	followTimer = GetTimeEX(),
	assistInCombat = true,
	isChecked = true,
	pause = false,
	enableHeals = true,
	message = 'Starting the follower...',
	navFunctionsLoaded = include("scripts\\script_nav.lua"),
	helperLoaded = include("scripts\\script_helper.lua"),
	extraFunctions = include("scripts\\script_followEX.lua"),
	unstuckLoaded = include("scripts\\script_unstuck.lua"),

}

function script_follow:window()
	if (self.isChecked) then 
		EndWindow();
		if(NewWindow("Follower Options", 320, 360)) then 
			script_followEX:menu();
		end
	end
end

function script_follow:moveInLineOfSight(partyMember)
	leaderObj = GetPartyMember(GetPartyLeaderIndex());
	if (not leaderObj:IsInLineOfSight() or leaderObj:GetDistance() > self.followLeaderDistance) then
			local x, y, z = leaderObj:GetPosition();
			script_nav:moveToTarget(GetLocalPlayer(), x , y, z);
			self.timer = GetTimeEX() + 200;
            self.message = "Moving to party member LoS";
		return true;
	end
	if (self.followMember) then
		if (not partyMember:IsInLineOfSight() and partyMember:GetDistance() < self.followLeaderDistance) then
			local x, y, z = partyMember:GetPosition();
			script_nav:moveToTarget(GetLocalPlayer(), x , y, z);
			self.timer = GetTimeEX() + 200;
			self.message = "Moving to party member LoS";
			return true;
		end
	end
return false;
end

function script_follow:healAndBuff()
	local localMana = GetLocalPlayer():GetManaPercentage();
	if (not IsStanding()) then 
		StopMoving();
	end
	-- Heals and buffs
	for i = 1, GetNumPartyMembers()+1 do
		local partyMember = GetPartyMember(i);
		if (i == GetNumPartyMembers()+1) then
			partyMember = GetLocalPlayer();
		end
		local partyMembersHP = partyMember:GetHealthPercentage();
		if (partyMembersHP > 0 and partyMembersHP < 99 and localMana > 1) then
			local partyMemberDistance = partyMember:GetDistance();
			leaderObj = GetPartyMember(GetPartyLeaderIndex());
			local localHealth = GetLocalPlayer():GetHealthPercentage();					

			-- Move in range: combat script return 3
			if (self.combatError == 3) then
				self.message = "Moving to target...";
				script_follow:moveInLineOfSight(partyMember);		
				return;
			end
			
			-- Move in line of sight and in range of the party member
			if (script_follow:moveInLineOfSight(partyMember)) then
				return true; 
			end

			-- Dispel Magic
			if (HasSpell("Dispel Magic")) and (localMana > 10) then 
				if (partyMember:HasDebuff("Druid's Slumber")) or (partyMember:HasDebuff("Terrify")) or (partyMember:HasDebuff("Frost Nova")) or 
				(partyMember:HasBuff("Screams of the Past")) or (partyMember:HasDebuff("Wavering Will")) then
					if (CastHeal("Dispel Magic", partyMember)) then
						self.waitTimer = GetTimeEX() + 1500;
						return true;
					end
				end				
			end
			
			-- Cure Disease
			if (HasSpell("Cure Disease")) and (localMana > 10) then
				if (partyMember:HasDebuff("Infected Wound")) then
					if (CastHeal("Cure Disease", partyMember)) then
						self.waitTimer = GetTimeEX() + 1500;
						return true;
					end
				end
			end

			-- purify
			if (HasSpell("Purify")) and (localMana > 10) then
				if (partyMember:HasDebuff("Irradiated")) or (partyMember:HasDebuff("Infected Wound")) then
					if (CastHeal("Purify", partyMember)) then
						self.waitTimer = GetTimeEX() + 1500;
						return true;
					end
				end
			end

			-- blessing of might
			if (not partyMember:HasBuff("Strength of Earth")) or (not partyMember:HasBuff("Mana Spring")) then
				if (partyMember:GetRagePercentage() > 1) or (partyMember:HasBuff("Bear Form") or partyMember:HasBuff("Cat Form")) then
					if (HasSpell("Blessing of Might")) and (not partyMember:HasBuff("Blessing of Might")) and (not partyMember:HasBuff("Blessing of Wisdom")) and (not partyMember:HasBuff("Strength of Earth")) then
						if (script_follow:moveInLineOfSight(partyMember)) then
							return true;
						end -- move to member
						if (Cast("Blessing of Might", partyMember)) then
            	    	 			self.waitTimer = GetTimeEX() + 1500;
					 		return true;
						end	
					end
				else
					if (HasSpell("Blessing of Wisdom")) and (not partyMember:HasBuff("Blessing of Wisdom")) and (not partyMember:HasBuff("Mana Spring")) then
						if (script_follow:moveInLineOfSight(partyMember)) then
							return true;
						end -- move to member
						if (Cast("Blessing of Wisdom", partyMember)) then
							self.waitTimer = GetTimeEX() + 1500;
							return true;
						end	
			   		end
				end
			end

			-- Power word Fortitude
			if (HasSpell("Power Word: Fortitude")) and (localMana > 40) and (not partyMember:HasBuff("Power Word: Fortitude")) then -- buff
				if (script_follow:moveInLineOfSight(partyMember)) or (script_follow:isTargetingPet(i)) then
					return true;
				end -- move to member
				if (Cast("Power Word: Fortitude", partyMember)) then
                    		self.waitTimer = GetTimeEX() + 1500;
					return true;
				end
			end	

			-- Divine Spirit
			if (HasSpell("Divine Spirit")) and (localMana > 30) and (not partyMember:HasBuff("Divine Spirit")) then
				if (script_follow:moveInLineOfSight(partyMember)) then
					return true;
				end -- move to member
				if (Cast("Divine Spirit", partyMember)) then
                   		self.waitTimer = GetTimeEX() + 1500;
					return true;
				end	
			end

			-- Arcane Intellect
			if (HasSpell("Arcane Intellect")) and (localMana > 40) and (not partyMember:HasBuff("Arcane Intellect")) then
				if (script_follow:moveInLineOfSight(partyMember)) then
					return true;
				end
				if (Cast("Arcane Intellect", partyMember)) then
                    		self.waitTimer = GetTimeEX() + 1500;
					return true;
				end
			end

			-- Inner Fire
			if (HasSpell("Inner Fire")) and (localMana > 30) and (not localObj:HasBuff("Inner Fire")) then
				if (Buff("Inner Fire", localObj)) then
					self.waitTimer = GetTimeEX() + 1500;
					return true;
				end
			end

			-- night elf Elune's Grace racial
			if (IsInCombat()) and (HasSpell("Elune's Grace")) and (not IsSpellOnCD("Elune's Grace")) and (not localObj:HasBuff("Elune's Grace")) and (localHealth < 75) then
				if (Buff("Elune's Grace", localObj)) then
					self.waitTimer = GetTimeEX() + 1500;
					return true;
				end
			end

			-- Quel'dorei Meditation on low mana
			if (HasSpell("Quel'dorei Meditation")) and (not IsSpellOnCD("Quel'dorei Meditation")) and (localMana < 20) then
				CastSpellByName("Quel'dorei Meditation");
			end
			
			-- priest fear
			if (script_follow:enemiesAttackingUs(5) > 3) and (HasSpell("Psychic Scream")) then
				if (CastSpellByName("Psychic Scream")) then
					return true;
				end
			end

			-- druid swiftmend
			if (HasSpell("Swiftmend")) and (not IsSpellOnCD("Swiftmend")) then
				if (partyMember:HasBuff("Regrowth")) or (partyMember:HasBuff("Rejuvenation")) then
					if (partyMembersHP < 30) then
						if (CastHeal("Swiftmend", partyMember)) then
							return true;
						end
					end
				end
			end

            -- enable / disble heals for follower
			if (self.enableHeals) or (partyMembersHP < 35 and not self.enableHeals) then

				-- flash heal 
				if (self.clickFlashHeal) then
					if (localMana > self.flashHealMana) and (partyMembersHP < self.partyFlashHealHealth) then
						if (script_follow:moveInLineOfSight(partyMember)) or (script_follow:isTargetingPet(i)) then
							return true;
				 		end -- move to member
						if (CastHeal("Flash Heal", partyMember)) then
							self.waitTimer = GetTimeEX() + 2000;
							return true;
						end
					end
				end

				-- inner focus
				if (HasSpell("Inner Focus")) and (not IsSpellOnCD("Inner Focus")) then
					if (localMana < self.flashHealMana and leaderObj:GetHealthPercentage() < self.partyFlashHealHealth) then
						if (Buff("Inner Focus", localObj)) then 
							self.waitTimer = GetTimeEX() + 1400;
							return true; 
						end
						if (CastHeal("Flash Heal", partyMember)) then
							self.waitTimer = GetTimeEX() + 1600;
							return true;
						end
					end
				end

				-- Power Infusion
				if (HasSpell("Power Infusion")) and (not IsSpellOnCD("Power Infusion")) then
					if (partyMembersHP< 50) or (script_priest:enemiesAttackingUs(8) > 1) then
				   	 	if (Buff("Power Infusion")) then
                            			self.waitTimer = GetTimeEX() + 1500;
				    			return true;
						end
					end
			    end

				-- Greater Heal
				if (self.clickGreaterHeal) then
					if (localMana > self.greaterHealMana) and (partyMembersHP < self.partyGreaterHealHealth) and (HasSpell("Greater Heal")) then
						if (script_follow:moveInLineOfSight(partyMember)) then
							return true;
				 		end -- move to member
						if (CastHeal("Greater Heal", partyMember)) then
							self.waitTimer = GetTimeEX() + 5500;
							return true;
						end
					end
				end

				-- Heal
				if (self.clickHeal) then
					if (localMana > self.healMana) and (partyMembersHP < self.partyHealHealth) and (HasSpell("Heal")) then
						if (script_follow:moveInLineOfSight(partyMember)) then
							return true;
				 		end -- move to member
						if (CastHeal("Heal", partyMember)) then
							self.waitTimer = GetTimeEX() + 2400;
							return true;
						end
					end
				end

				-- Lesser Heal
               		-- level 20+ at very low mana
				if (localObj:GetLevel() >= 20) then
					if (localMana < 6) and (partyMembersHP < 20) then
						if (script_follow:moveInLineOfSight(partyMember)) then
							return true;
				 		end -- move to member	
						if (CastHeal("Lesser Heal", partyMember)) then
							self.waitTimer = GetTimeEX() + 2400;
							return true;
						end
					end
                    -- below level 20 cast lesser heal
				elseif (localObj:GetLevel() <= 20) then
					if (localMana > self.lesserHealMana) and (partyMembersHP < self.partyLesserHealHealth) and (HasSpell("Lesser Heal")) then
						if (script_follow:moveInLineOfSight(partyMember)) then
							return true;
				 		end -- move to member
						if (CastHeal("Lesser Heal", partyMember)) then
							self.waitTimer = GetTimeEX() + 2400;
							return true;
						end
					end
				end

				-- Renew
				if (self.clickRenew) then
					if (localMana > self.renewMana) and (partyMembersHP < self.partyRenewHealth) and (not partyMember:HasBuff("Renew")) and (HasSpell("Renew")) then
						if (script_follow:moveInLineOfSight(partyMember)) then
							return true;
				 		end -- move to member
						if (CastHeal("Renew", partyMember)) then
							self.waitTimer = GetTimeEX() + 1650;
							return true;
						end
					end
				end

				-- Shield
				if (self.clickShield) then
					if (localMana > self.shieldMana) and (partyMembersHP < self.partyShieldHealth) and (not partyMember:HasDebuff("Weakened Soul")) and (HasSpell("Power Word: Shield")) then
						if (script_follow:moveInLineOfSight(partyMember)) then
							return true;
				 		end -- move to member
						if (CastHeal("Power Word: Shield", partyMember)) then 
							self.waitTimer = GetTimeEX() + 1550;
							return true; 
						end
					elseif (self.clickRenew) then
						if (localMana > self.renewMana) and (partyMembersHP < self.partyShieldHealth) and (not partyMember:HasBuff("Renew")) and (HasSpell("Renew")) then
							if (script_follow:moveInLineOfSight(partyMember)) then
								return true;
				 			end -- move to member
							if (CastHeal("Renew", partyMember)) then
								self.waitTimer = GetTimeEX() + 1550;
								return true;
							end
						end
					end
				end

				-- Blessing of Protection
				if (localMana > 5) and (partyMembersHP < self.bopHealth) and (HasSpell("Blessing of Protection")) then
					if (script_follow:moveInLineOfSight(partyMember)) then
						return true;
				 	end -- move to member
					if (Cast("Blessing of Protection", partyMember)) then
						self.waitTimer = GetTimeEX() + 1500;
						return true;
					end
				end

				-- Lay on Hands
				if (localMana < 25) and (partyMembersHP < self.layOnHandsHealth) and (HasSpell("Lay on Hands")) then
					if (script_follow:moveInLineOfSight(partyMember)) then
						return true;
				 	end -- move to member
					if (CastHeal("Lay on Hands", partyMember)) then
						self.waitTimer = GetTimeEX() + 1500;
						return true;
					end
				end

				-- Holy Light
				if (localMana > self.holyLightMana) and (partyMembersHP < self.partyHolyLightHealth) and (HasSpell("Holy Light")) then
					if (script_follow:moveInLineOfSight(partyMember)) then
						return true;
				 	end -- move to member
					if (CastHeal("Holy Light", partyMember)) then
						self.waitTimer = GetTimeEX() + 2700;
						return true;
					end
				end

				-- Flash Of Light
				if (localMana > self.flashOfLightMana) and (partyMembersHP < self.partyFlashOfLightHealth) and (HasSpell("Flash of Light")) then
					if (script_follow:moveInLineOfSight(partyMember)) then
						return true;
				 	end -- move to member
					if (CastHeal("Flash of Light", partyMember)) then
						self.waitTimer = GetTimeEX() + 1700;
						return true;
					end
				end                

			-- natures swiftness
			if (HasSpell("Nature's Swiftness")) and (not localObj:HasBuff("Nature's Swiftness")) and (leaderObj:GetHealthPercentage() < 30) then
				if (not IsSpellOnCD("Nature's Swiftness")) and (localMana > 10) then
					if (script_follow:moveInLineOfSight(partyMember)) then
						return true;
					end -- move to member
					if (CastSpellByName("Nature's Swiftness")) then
						self.waitTimer = GetTimeEX() + 1500;
						return true;
					end
				end
			end
                
                -- regrowth
                if (self.clickRegrowth) then
                    if (HasSpell("Regrowth")) and (not targetObj:HasBuff("Regrowth")) and (partyMembersHP < self.regrowthHealth) and (localMana > self.regrowthMana) then
                        if (script_follow:moveInLineOfSight(partyMember)) then
                            return true;
                        end -- move to member
                        if (CastSpellByName("Regrowth")) then
                            self.waitTimer = GetTimeEX() + 1500;
                            return true;
                        end
                    end
                end

			-- rejuvenation
			if (HasSpell("Rejuvenation")) and (not targetObj:HasBuff("Rejuvenation")) and (partyMembersHP < self.rejuvenationHealth) and (localMana > self.rejuvenationMana) then
				if (script_follow:moveInLineOfSight(partyMember)) then
                     	   return true;
				end -- move to member
				if (CastSpellByName("Rejuvenation")) then
					self.waitTimer = GetTimeEX() + 1500;
				return true;
				end
			end

                -- healing touch if has regrowth
                if (self.clickHealingTouch) then
                    if (HasSpell("Healing Touch")) and (targetObj:HasBuff("Regrowth")) and (partyMembersHP < self.healingTouchHealth) and (localMana > self.healingTouchMana) then
                        if (script_follow:moveInLineOfSight(partyMember)) then
                            return true;
                        end -- move to member
                        if (CastSpellByName("Healing Touch")) then
                            self.waitTimer = GetTimeEX() + 1500;
                            return true;
                        end
                    end
                end
            end
		end
    end
    return false;
end

function script_follow:setup()
	self.lootCheck['timer'] = 0;
	self.lootCheck['target'] = 0;
	script_helper:setup();
	self.isSetup = true;
end

function script_follow:setWaitTimer(ms)
	self.waitTimer = GetTimeEX() + ms;
end

function script_follow:GetPartyLeaderObject() 
	if GetNumPartyMembers() > 0 then -- are we in a party?
		leaderObj = GetPartyMember(GetPartyLeaderIndex());
		if (leaderObj ~= nil) then
			return leaderObj;
		end
	end
	return 0;
end

function script_follow:run()
	script_follow:window();
	-- Set next to node distance and nav-mesh smoothness to double that number
	if (IsMounted()) then
		script_nav:setNextToNodeDist(6); NavmeshSmooth(14);
	else
		script_nav:setNextToNodeDist(self.nextToNodeDist);
		NavmeshSmooth(self.nextToNodeDist*3);
	end
	
	if (not self.isSetup) then
		script_follow:setup();
	end
	
	if (not self.navFunctionsLoaded) then
		self.message = "Error script_nav not loaded...";
		return;
	end
	if (not self.helperLoaded) then	
		self.message = "Error script_helper not loaded..."; 
		return;
	end

	if (self.pause) then 
		self.message = "Paused by user..."; 
		return; 
	end

	-- auto unstuck feature
	if (self.useUnStuck) then
		if (not script_unstuck:pathClearAuto(2)) then
			self.message = script_unstuck.message;
			return;
		end
	end

	localObj = GetLocalPlayer();

	if(GetTimeEX() > self.timer) then
		self.timer = GetTimeEX() + self.tickRate;

		-- Wait out the wait-timer and/or casting or channeling
		if (self.waitTimer > GetTimeEX() or IsCasting() or IsChanneling()) then
			return;
		end

		-- Automatic loading of the nav mesh
		if (not IsUsingNavmesh()) then 
			UseNavmesh(true);
			return; 
		end
		if (not LoadNavmesh()) then 
			self.message = "Make sure you have mmaps-files...";
			return;
		end
		if (GetLoadNavmeshProgress() ~= 1) then
			self.message = "Loading the nav mesh... ";
			return; 
		end

		-- Corpse-walk if we are dead
		if(localObj:IsDead()) then
			self.message = "Walking to corpse...";
			-- Release body
			if(not IsGhost()) then 
				RepopMe(); 
				self.waitTimer = GetTimeEX() + 5000;
				return; 
			end
			-- Ressurrect within the ress distance to our corpse
			local _lx, _ly, _lz = localObj:GetPosition();

			if(GetDistance3D(_lx, _ly, _lz, GetCorpsePosition()) > self.ressDistance) then
				script_nav:moveToNav(localObj, GetCorpsePosition());
				return;
			else
				if (script_aggro:safeRess()) then
					script_follow.message = "Finding a safe spot to ress...";
					return true;
				end
				RetrieveCorpse();
			end
			return;
		end

		-- Check: Rogue only, If we just Vanished, move away from enemies within 30 yards
		if (localObj:HasBuff("Vanish")) then
			if (script_nav:runBackwards(1, 30)) then 
				ClearTarget(); 
				self.message = "Moving away from enemies..."; 
				return; 
			end 
		end
		
		-- Rest
		if (not IsInCombat() and script_follow:enemiesAttackingUs() == 0 and not localObj:HasBuff('Feign Death')) then
			if(RunRestScript()) then
				self.message = "Resting...";
				-- Stop moving
				if (IsMoving() and not localObj:IsMovementDisabed()) then
					StopMoving(); 
					return; 
				end
				-- Dismount
				if (IsMounted()) then
					DisMount(); 
					return; 
				end
				-- Add 2500 ms timer to the rest script rotations (timer could be set already)
				if ((self.waitTimer - GetTimeEX()) < 2500) then
					self.waitTimer = GetTimeEX()+2500;
				end
			return;	
			end
		end

		-- If bags are full
		if (AreBagsFull() and not IsInCombat()) then
			self.message = 'Warning bags are full...';
		end

		-- Clear dead/tapped targets
		if (self.enemyObj ~= 0 and self.enemyObj ~= nil) then
			if ((self.enemyObj:IsTapped() and not self.enemyObj:IsTappedByMe()) 
				or self.enemyObj:IsDead()) then
				self.enemyObj = nil;
				ClearTarget();
			end
		end

		-- Accept group invite
		if (GetNumPartyMembers() < 1 and self.acceptTimer < GetTimeEX()) then 
			self.acceptTimer = GetTimeEX() + 5000;
			AcceptGroup(); 
		end

		-- Healer check: heal/buff the party
		if (script_follow:healAndBuff()) and (HasSpell("Smite") or HasSpell("Rejuvenation") or HasSpell("Healing Wave") or HasSpell("Holy Light")) then
			self.message = "Healing/buffing the party...";
			return;
		end

		-- Loot
		if (not IsInCombat() and script_follow:enemiesAttackingUs() == 0 and not localObj:HasBuff('Feign Death')) then
			-- Loot if there is anything lootable and we are not in combat and if our bags aren't full
			if (not self.skipLooting and not AreBagsFull()) then 
				self.lootObj = script_nav:getLootTarget(self.findLootDistance);
			else
				self.lootObj = nil;
			end
			if (self.lootObj == 0) then
				self.lootObj = nil; 
			end
			local isLoot = not IsInCombat() and not (self.lootObj == nil);
			if (isLoot and not AreBagsFull()) then
				script_grindEX:doLoot(localObj);
				return;
			elseif (AreBagsFull() and not hsWhenFull) then
				self.lootObj = nil;
				self.message = "Warning the bags are full...";
			end
		end

		-- Assign the next valid target to be killed
		-- Check if anything is attacking us Priest
		if (script_follow:enemiesAttackingUs() >= 1) then
			local localMana = GetLocalPlayer():GetManaPercentage();
			if (localMana > 6 and HasSpell('Fade') and not IsSpellOnCD('Fade')) then
				CastSpellByName('Fade');
				return;
			end
		end
				
		-- Check if anything is attacking us Paladin
		if (script_follow:enemiesAttackingUs() >= 2) then
			local localMana = GetLocalPlayer():GetManaPercentage();
			if (localMana > 6 and HasSpell('Divine Protection') and not IsSpellOnCD('Divine Protection')) then
				CastSpellByName('Divine Protection');
				return;
			end
		end
        
		if (GetTarget() ~= 0 and GetTarget() ~= nil) and (script_follow:GetPartyLeaderObject():GetDistance() < self.followLeaderDistance) then
            	local target = GetTarget();
				if (target:CanAttack() and self.assistInCombat) then
					self.enemyObj = target;
				else
					self.enemyObj = nil;
				end 

		else

		if (script_follow:GetPartyLeaderObject() ~= 0) then
			if (script_follow:GetPartyLeaderObject():GetUnitsTarget() ~= 0 and not script_follow:GetPartyLeaderObject():IsDead()) and (script_follow:GetPartyLeaderObject():GetDistance() < self.followLeaderDistance) then
				if (script_follow:GetPartyLeaderObject():GetUnitsTarget():GetHealthPercentage() <= self.dpsHP and self.assistInCombat) then
					self.enemyObj = script_follow:GetPartyLeaderObject():GetUnitsTarget();
					script_follow:moveInLineOfSight(partyMember);
				else
				self.enemyObj = nil;
				end
			end
            end
	end	

		-- Finish loot before we engage new targets or navigate
		if (self.lootObj ~= nil and not IsInCombat()) and (script_follow:GetPartyLeaderObject():GetDistance() < self.followLeaderDistance) then
			return; 
		else
			-- reset the combat status
			self.combatError = nil; 
			-- Run the combat script and retrieve combat script status if we have a valid target
			if (self.enemyObj ~= nil and self.enemyObj ~= 0) then
				self.combatError = RunCombatScript(self.enemyObj:GetGUID());
			end
		end

			if (self.enemyObj ~= nil or IsInCombat()) then
				self.message = "Running the combat script...";
				-- In range: attack the target, combat script returns 0
				if(self.combatError == 0) then
					script_nav:resetNavigate();
					if IsMoving() then
						StopMoving(); 
						return;
					end
				end
				-- Invalid target: combat script return 2
				if(self.combatError == 2) then
					-- TODO: add blacklist GUID here
					self.enemyObj = nil;
					ClearTarget();
					return;
				end
				-- Move in range: combat script return 3
				if (self.combatError == 3) then
					self.message = "Moving to target...";
					local _x, _y, _z = self.enemyObj:GetPosition();
					self.message = script_nav:moveToTarget(GetLocalPlayer(), _x, _y, _z);
					return;
				end
			
				-- Do nothing, return : combat script return 4
				if(self.combatError == 4) then
					return;
				end

				-- Target player pet/totem: pause for 5 seconds, combat script should add target to blacklist
				if(self.combatError == 5) then
					self.message = "Targeted a player pet pausing 5s...";
					ClearTarget();
					self.waitTimer = GetTimeEX()+5000;
					return;
				end

				-- Stop bot, request from a combat script
				if(self.combatError == 6) then
					self.message = "Combat script request stop bot...";
					Logout();
					StopBot();
					return;
				end
			end
		

		-- Pre checks before navigating
		if(IsLooting() or IsCasting() or IsChanneling() or IsDrinking() or IsEating() or IsInCombat()) then 
			return;
		end

		-- Mount before we follow our master
		--if (script_follow:mountUp()) then return; end		
		
		-- Follow our master
		if (script_follow:GetPartyLeaderObject() ~= 0) then
			if(script_follow:GetPartyLeaderObject():GetDistance() > self.followLeaderDistance and not script_follow:GetPartyLeaderObject():IsDead()) then
				local x, y, z = script_follow:GetPartyLeaderObject():GetPosition();
				self.message = "Following our master...";
				script_nav:moveToTarget(GetLocalPlayer(), x, y, z);
				return;
			end
		end
	end 
end

function script_follow:getTarget()
	return self.enemyObj;
end

function script_follow:getTargetAttackingUs() 
    local currentObj, typeObj = GetFirstObject(); 
    while currentObj ~= 0 do 
    	if typeObj == 3 then
			if (currentObj:CanAttack() and not currentObj:IsDead()) then
				local localObj = GetLocalPlayer();		
				if (currentObj:GetUnitsTarget() == localObj) then 
                	return currentObj; 
				end 
			end
		end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return nil;
end

function script_follow:assignTarget() 
        -- Instantly return the last target if we attacked it and it's still alive and we are in combat
        if (self.enemyObj ~= 0 and self.enemyObj ~= nil and not self.enemyObj:IsDead() and IsInCombat()) then
            if (script_follow:isTargetingMe(self.enemyObj) 
                or script_follow:isTargetingPet(self.enemyObj) 
                or self.enemyObj:IsTappedByMe()) then
                return self.enemyObj;
            end
        end

        -- Find the closest valid target if we have no target or we are not in combat
        local mobDistance = self.pullDistance;
        local closestTarget = nil;
        local i, targetType = GetFirstObject();
        while i ~= 0 do
            if (targetType == 3 and not i:IsCritter() and not i:IsDead() and i:CanAttack()) then
                if (script_follow:enemyIsValid(i)) then
                    -- save the closest mob or mobs attacking us
                    if (mobDistance > i:GetDistance()) then
                        mobDistance = i:GetDistance();	
                        closestTarget = i;
                    end
                end
            end
            i, targetType = GetNextObject(i);
        end
        
        -- Check: If we are in combat but no valid target, kill the "unvalid" target attacking us
        if (closestTarget == nil and IsInCombat()) then
            if (GetTarget() ~= 0) then
                return GetTarget();
            end
        end

        -- Return the closest valid target or nil
        return closestTarget;
 end

function script_follow:isTargetingPet(i)
	local class = UnitClass("player");
	if (not class == 'Warlock') then
		local pet = GetPet();
		if (pet ~= nil and pet ~= 0 and not pet:IsDead()) then
			if (i:GetUnitsTarget() ~= nil and i:GetUnitsTarget() ~= 0) then
				return i:GetUnitsTarget():GetGUID() == pet:GetGUID();
			end
		end
		return false;
	end
end

function script_follow:isTargetingMe(i) 
	local localPlayer = GetLocalPlayer();
	if (localPlayer ~= nil and localPlayer ~= 0 and not localPlayer:IsDead()) then
		if (i:GetUnitsTarget() ~= nil and i:GetUnitsTarget() ~= 0) then
			return i:GetUnitsTarget():GetGUID() == localPlayer:GetGUID();
		end
	end
	return false;
end

function script_follow:enemyIsValid(i)
	if (i ~= 0) then
		-- Valid Targets: Tapped by us, or is attacking us or our pet
		if (script_follow:isTargetingMe(i)
			or (script_follow:isTargetingPet(i) and (i:IsTappedByMe() or not i:IsTapped())) 
			or (i:IsTappedByMe() and not i:IsDead())) then 
				return true; 
		end
		-- Valid Targets: Within pull range, levelrange, not tapped, not skipped etc
		if (not i:IsDead() and i:CanAttack() and not i:IsCritter()
			and ((i:GetLevel() <= self.maxLevel and i:GetLevel() >= self.minLevel))
			and i:GetDistance() < self.pullDistance and (not i:IsTapped() or i:IsTappedByMe())
			and not script_follow:isTargetBlacklisted(i:GetGUID()) 
			and not (self.skipHumanoid and i:GetCreatureType() == 'Humanoid')
			and not (self.skipDemon and i:GetCreatureType() == 'Demon')
			and not (self.skipBeast and i:GetCreatureType() == 'Beast')
			and not (self.skipElemental and i:GetCreatureType() == 'Elemental')
			and not (self.skipUndead and i:GetCreatureType() == 'Undead') 
			and not (self.skipElites and (i:GetClassification() == 1 or i:GetClassification() == 2))
			) then
			return true;
		end
	end
	return false;
end

function script_follow:enemiesAttackingUs() -- returns number of enemies attacking us
	local unitsAttackingUs = 0; 
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
		if typeObj == 3 then
			if (currentObj:CanAttack() and not currentObj:IsDead()) then
				if (script_follow:isTargetingMe(currentObj)) then 
					unitsAttackingUs = unitsAttackingUs + 1; 
                end 
            end 
       	end
      	currentObj, typeObj = GetNextObject(currentObj); 
	end
   	return unitsAttackingUs;
end

function script_follow:playersTargetingUs() -- returns number of players attacking us
	local nrPlayersTargetingUs = 0; 
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
		if typeObj == 4 then
			if (script_follow:isTargetingMe(currentObj)) then 
                nrPlayersTargetingUs = nrPlayersTargetingUs + 1; 
			end 
		end
        currentObj, typeObj = GetNextObject(currentObj); 
	end
    return nrPlayersTargetingUs;
end

function script_follow:playersWithinRange(range)
	local currentObj, typeObj = GetFirstObject(); 
	while currentObj ~= 0 do 
    	if (typeObj == 4 and not currentObj:IsDead()) then
			if (currentObj:GetDistance() < range) then 
				local localObj = GetLocalPlayer();
				if (localObj:GetGUID() ~= currentObj:GetGUID()) then
                	return true;
				end
			end 
       	end
        currentObj, typeObj = GetNextObject(currentObj); 
    end
    return false;
end

function script_follow:getDistanceDif()
	local x, y, z = GetLocalPlayer():GetPosition();
	local xV, yV, zV = self.myX-x, self.myY-y, self.myZ-z;
	return math.sqrt(xV^2 + yV^2 + zV^2);
end

function script_follow:draw()
	script_followEX:drawStatus();	
end