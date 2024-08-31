_questDB = { isSetup = false, questList = {}, numQuests = 0, curListQuest = 0,
		includeElwynnNorthshire = include("scripts\\db\\_questDB_Elwynn_Northshire.lua"),


}

function _questDB:setup()

	-- type quest 1 = kill 2 = gather 0 = already completed

--[[is completed, faction, quest name, quest giver name, quest giver pos, mapID, minLevel, maxLevel, grind pos, type, kill number, gather number, return pos, return target name, kill target 1, kill target 2, gather target 1, gather target 2, rewardNum]]--

-- level 1 night elf starter quest
_questDB:addQuest("no", 0, "The Balance of Nature", "Conservator Ilthalaine", 10354.408203125, 675.88238525391, 1329.5684814453, 141, 1, 4, 10328.900390625, 826.05200195313, 1326.380859375, 1, 7, 0, 10354.408203125, 675.88238525391, 1329.5684814453, "Conservator Ilthalaine", "Young Nightsaber", "Young Thistleboar", 0, 0, 0);

	_questDB_Elwynn_Northshire:setup()

	self.isSetup = true;

end


function _questDB:addQuest(completed, faction, questName, giverName, posX, posY, posZ, mapID, minLevel, maxLevel, grindX, grindY, grindZ, type, numKill, numGather, returnX, returnY, returnZ, returnTarget, enemyName, enemyName2, gatherName, gatherName2, rewardNum)
	self.questList[self.numQuests] = {};
	self.questList[self.numQuests]['completed'] = completed;
	self.questList[self.numQuests]['faction']= faction;
	self.questList[self.numQuests]['questName'] = questName;
	self.questList[self.numQuests]['giverName'] = giverName;
	self.questList[self.numQuests]['pos'] = {};
	self.questList[self.numQuests]['pos']['x'] = posX;
	self.questList[self.numQuests]['pos']['y'] = posY;
	self.questList[self.numQuests]['pos']['z'] = posZ;
	self.questList[self.numQuests]['mapID'] = mapID;
	self.questList[self.numQuests]['minLevel'] = minLevel;
	self.questList[self.numQuests]['maxLevel'] = maxLevel;
	self.questList[self.numQuests]['grindPos'] = {};
	self.questList[self.numQuests]['grindPos']['grindX'] = grindX;
	self.questList[self.numQuests]['grindPos']['grindY'] = grindY;
	self.questList[self.numQuests]['grindPos']['grindZ'] = grindZ;
	self.questList[self.numQuests]['type'] = type;
	self.questList[self.numQuests]['numKill'] = numKill;
	self.questList[self.numQuests]['numGather'] = numGather;
	self.questList[self.numQuests]['returnPos'] = {};
	self.questList[self.numQuests]['returnPos']['returnX'] = returnX;
	self.questList[self.numQuests]['returnPos']['returnY'] = returnY;
	self.questList[self.numQuests]['returnPos']['returnZ'] = returnZ;
	self.questList[self.numQuests]['returnTarget'] = returnTarget;
	self.questList[self.numQuests]['targetName'] = enemyName;
	self.questList[self.numQuests]['targetName2'] = enemyName2;
	self.questList[self.numQuests]['gatherName'] = gatherName;
	self.questList[self.numQuests]['gatherName2'] = gatherName2;
	self.questList[self.numQuests]['rewardNum'] = rewardNum;

	self.numQuests = self.numQuests + 1;

end


-- we need to run a check for faction first and foremost...




function _questDB:getQuestStartPos()
local x, y, z = 0, 0, 0;
local dist = 0;
local bestDist = 10000;
	if (not self.isSetup) then
		_questDB:setup();
	end

	for i=0, self.numQuests -1 do
		if self.questList[i]['completed'] ~= "nnil" then
			if self.questList[i]['mapID'] == GetMapID() then
					x, y, z = self.questList[i]['pos']['x'], self.questList[i]['pos']['y'], self.questList[i]['pos']['z'];

				-- set our quest to be checked through rest of script?
				self.curListQuest = self.questList[i]['questName'];
			end
		end
	end

return x, y, z;
end

function _questDB:getQuestGiverName()
local name = "";
local dist = 0;
local bestDist = 10000;

if (not self.isSetup) then
		_questDB:setup();
	end

	for i=0, self.numQuests -1 do
		if self.questList[i]['completed'] ~= "nnil" then
			if self.questList[i]['mapID'] == GetMapID() then

			local dist = self.questList[i]['pos']['x'], self.questList[i]['pos']['y'], self.questList[i]['pos']['z'];

				
					x, y, z = self.questList[i]['pos']['x'], self.questList[i]['pos']['y'], self.questList[i]['pos']['z'];
			

					if self.questList[i]['questName'] == self.curListQuest then
						name = self.questList[i]['giverName'];
					end
			end
		end
	end

return name;
end

function _questDB:getQuestName()
local name = "";

		name = self.curListQuest;
return name;
end

function _questDB:getQuestGrindPos()
local x, y, z = 0, 0, 0;

if (not self.isSetup) then
		_questDB:setup();
	end

	for i=0, self.numQuests -1 do
		if self.questList[i]['completed'] ~= "nnil" then
			if self.questList[i]['questName'] == _quest.currentQuest then
				x, y, z = self.questList[i]['grindPos']['grindX'], self.questList[i]['grindPos']['grindY'], self.questList[i]['grindPos']['grindZ'];
			end
		end
	end

return x, y, z;
end

function _questDB:getObjectives()

	-- entry 1...
	ToggleQuestLog()
	SelectQuestLogEntry(1);
	local desc, type, done = GetQuestLogLeaderBoard(1, 2)
	DEFAULT_CHAT_FRAME:AddMessage(desc);
end

function _questDB:getTarget()
	local target = 0;
	local target2 = 0;
	local i, t = GetFirstObject();

if (not self.isSetup) then
		_questDB:setup();
	end

	if _quest.currentQuest ~= nil then
		for i=0, self.numQuests -1 do
			if self.questList[i]['questName'] == _quest.currentQuest then
				target = self.questList[i]['targetName'];
				target2 = self.questList[i]['targetName2'];
			end
		end
	end
	while i ~= 0 do
		if t == 3 then
			if i:GetDistance() <= 50 and (i:GetUnitName() == target or i:GetUnitName() == target2) and not i:IsDead() then
				i:AutoAttack();
				return i;
			elseif script_grindEX:returnTargetNearMyAggroRange() ~= nil then
				script_grindEX:returnTargetNearMyAggroRange():AutoAttack();
				return script_grindEX:returnTargetNearMyAggroRange();
			end
		end
	i, t = GetNextObject(i);
	end
return nil;
end

function _questDB:getReturnTargetPos()
local x, y, z = 0, 0, 0;

if (not self.isSetup) then
		_questDB:setup();
	end
	
	if self.curListQuest ~= nil then
	for i=0, self.numQuests -1 do
		if self.questList[i]['completed'] ~= "nnil" then
			if self.questList[i]['questName'] == self.curListQuest then
				x, y, z = self.questList[i]['returnPos']['returnX'], self.questList[i]['returnPos']['returnY'], self.questList[i]['returnPos']['returnZ'];
			end
		end
	end
	end

return x, y, z;
end

function _questDB:getReturnTargetName()	
local x, y, z = 0, 0, 0;

if (not self.isSetup) then
		_questDB:setup();
	end

	for i=0, self.numQuests -1 do
		if self.questList[i]['completed'] ~= "nnil" then
			if self.questList[i]['questName'] == self.curListQuest then
				name = self.questList[i]['returnTarget'];
			end
		end
	end

return name;
end

function _questDB:turnQuestCompleted()

if (not self.isSetup) then
		_questDB:setup();
	end

	for i=0, self.numQuests do
		if self.questList[i]['questName'] == self.curListQuest then
			if self.questList[i]['completed'] ~= "nnil" then
				self.questList[i]['completed'] = "nnil";
				_quest.currentQuest = nil;
				self.curListQuest = nil;
				DEFAULT_CHAT_FRAME:AddMessage("Quest marked as complete");
				return true;
			end
		end
	end
return false;
end
