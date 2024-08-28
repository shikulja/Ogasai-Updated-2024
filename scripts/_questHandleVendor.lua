_questHandleVendor = {}

function _questHandleVendor:vendor()
	if (not IsInCombat()) then
		local vendorStatus = script_vendor:getStatus();
		if (vendorStatus == 1) then
			_quest.message = "Repairing at vendor...";
			if (script_vendor:repair()) then script_grind:setWaitTimer(100);
				return true;
			end
	
		elseif (vendorStatus == 2) then
			_quest.message = "Selling to vendor...,";
			if (script_vendor:sell()) then script_grind:setWaitTimer(100);
				return true;
			end
		elseif (vendorStatus == 3) then
			_quest.message = "Buying ammo at vendor...";
			if (script_vendor:continueBuyAmmo()) then 
				script_grind:setWaitTimer(100);
				return true; 
			end
		elseif (vendorStatus == 4) then
			_quest.message = "Buying food/drink at vendor...";
			if (script_vendor:continueBuy()) then script_grind:setWaitTimer(100);
				return true;
			end
		end
	end
return false;
end