script_rogueFollowerHeals = {

}

function script_rogueFollowerHeals:HealsAndBuffs()

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
			if (script_follow.combatError == 3) then
				script_follow.message = "Moving to target...";
				script_follow:moveInLineOfSight(partyMember);		
				return;
			end
			
			-- Move in line of sight and in range of the party member
			if (script_follow:moveInLineOfSight(partyMember)) then
				return true; 
			end

            -- spell name here
            if (HasSpell(" ")) and (localMana > x ) and (not partyMember:HasBuff(" ")) then
                if (script_follow:moveInLineOfSight(partyMember)) then
                    return true;
                end
                if (Cast(" ", partyMember)) then
                        self.waitTimer = GetTimeEX() + 1500;
                    return true;
                end
            end
        end
    end
	return;
end