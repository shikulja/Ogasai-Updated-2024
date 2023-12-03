script_shamanEX2 = {


}


function script_shamanEX2:useTotem()

	local localMana = GetLocalPlayer():GetManaPercentage();
	local hasTarget = GetLocalPlayer():GetUnitsTarget();

	-- Totem 1
	if (script_shaman.useEarthTotem) and (targetHealth >= 30) and (hasTarget ~= 0) then
		if (targetObj:GetDistance() <= 20) and (localMana >= 20) and (HasSpell(script_shaman.totem))
			and (not localObj:HasBuff(script_shaman.totemBuff)) then
			if (CastSpellByName(script_shaman.totem)) then
				script_shaman.waitTimer = GetTimeEX() + 1750;
					return 4;
			end
			return true;
		end
	end

	-- totem 3
	if (script_shaman.useWaterTotem) and (not localObj:HasBuff(script_shaman.totem3Buff)) and (hasTarget ~= 0) then
		if (targetObj:GetDistance() <= 20) and (localMana >= 20) and (HasSpell(script_shaman.totem3)) then
			if (CastSpellByName(script_shaman.totem3)) then
				script_shaman.waitTimer = GetTimeEX() + 1750;
				return 4;
			end
			return true;
		end
	end

return false;
end

function script_shamanEX2:menu()

	if (CollapsingHeader("Shaman Heal Options")) then
		Text('Rest options:');
		script_shaman.eatHealth = SliderInt("Eat below HP%", 1, 100, script_shaman.eatHealth);
		script_shaman.drinkMana = SliderInt("Drink below Mana%", 1, 100, script_shaman.drinkMana);
		Text('You can add more food/drinks in script_helper.lua');

		Separator();

		script_shaman.potionHealth = SliderInt("Potion below HP%", 1, 99, script_shaman.potionHealth);
		script_shaman.potionMana = SliderInt("Potion below Mana%", 1, 99, script_shaman.potionMana);

		Separator();

		Text("Heal Below Health In Combat");
		script_shaman.healHealth = SliderInt("Heal when below HP% (in combat)", 1, 99, script_shaman.healHealth);

	end

end
