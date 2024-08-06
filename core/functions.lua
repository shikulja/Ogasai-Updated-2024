script_functions = {

}


-- druid or shaman check forms
function HasForm()

	if (GetLocalPlayer():HasBuff("Bear Form"))
		or (GetLocalPlayer():HasBuff("Dire Bear Form"))
		or (GetLocalPlayer():HasBuff("Cat Form"))
		or (GetLocalPlayer():HasBuff("Aquatic Form"))
		or (GetLocalPlayer():HasBuff("Travel Form"))
		or (GetLocalPlayer():HasBuff("Moonkin Form"))
		or (GetLocalPlayer():HasBuff("Ghost Wolf"))
	then
		return true;
	end
return false;
end

function IsMoonkinForm()

	if (GetLocalPlayer():HasBuff("Moonkin Form"))

	then
		return true;
	end
end

-- druid has cat form
function IsCatForm()

	if (GetLocalPlayer():HasBuff("Cat Form"))
	
	then
		return true;
	end

return false;
end

-- druid has bear form
function IsBearForm()
	
	if (GetLocalPlayer():HasBuff("Bear Form"))
		or (GetLocalPlayer():HasBuff("Dire Bear Form"))
	
	then
		return true;

	end
return false;
end

-- druid has travel form
function IsTravelForm()
	
	if (GetLocalPlayer():HasBuff("Travel Form"))

	then
		return true;
	end
return false;
end

-- druid has aquatic form
function IsAquaticForm()
	
	if (GetLocalPlayer():HasBuff("Aquatic Form"))

	then
		return true;
	end
return false;
end

function CastGhostWolf()

	if (HasSpell("Ghost Wolf")) and (not GetLocalPlayer():HasBuff("Ghost Wolf")) and (not IsSpellOnCD("Ghost Wolf")) then
		CastSpellByName("Ghost Wolf", GetLocalPlayer());
		return true;
	end
return false;
end

-- shaman has ghost wolf form
function IsGhostWolf()
	
	if (GetLocalPlayer():HasBuff("Ghost Wolf"))

	then
		return true;
	end
return false;
end

function PetHasTarget()
	
	if (GetPet() ~= 0) then
		if (GetPet():GetUnitsTarget() ~= 0) then
			return true;
		end
	end
return false;
end

function PlayerHasTarget()
	
	if (GetLocalPlayer():GetUnitsTarget() ~= 0) then
		return true;
	end
return false;
end

function HasPet()
	if (GetPet() ~= 0) then
		if (GetPet():GetHealthPercentage() > 0) then
			return true;
		end
	end
return false;
end

function CallPet()

	if (GetPet() == 0) then
		script_hunter.message = "GetPet() is missing, calling GetPet()...";
		CastSpellByName("Call Pet");
		return true;
	end
return false;
end

function CastStealth()

	if (HasSpell("Stealth")) or (HasSpell("Prowl")) and (not script_checkDebuffs:hasMagic()) and (not script_checkDebuffs:hasPoison()) and (not script_checkDebuffs:hasCurse()) and (not IsStealth()) then
		if (HasSpell("Stealth")) and (script_rogue.useStealth) then
			if (not IsSpellOnCD("Stealth")) then
				CastSpellByName("Stealth", GetLocalPlayer());
				script_grind:setWaitTimer(1500);
				return true;
			end
		elseif (HasSpell("Prowl")) and (script_druid.useStealth) then
			if (not HasForm()) then
				if (HasSpell("Cat Form")) then
					CastSpellByName("Cat Form");
					return true;
				end
			elseif (not IsSpellOnCD("Prowl")) and (IsCatForm()) then
				CastSpellByName("Prowl", GetLocalPlayer());
				script_grind:setWaitTimer(1500);
				return true;
			end
		end
	end
return false;
end

function IsStealth()

	if (GetLocalPlayer():HasBuff("Stealth")) or (GetLocalPlayer():HasBuff("Prowl")) then
		return true;
	end
return false;
end

function CastSprint()
	if (HasSpell("Sprint")) and (not IsSpellOnCD("Sprint")) then
		CastSpellByName("Sprint");
		return true;
	end
return false;
end