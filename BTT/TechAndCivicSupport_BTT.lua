print("Loading TechAndCivicSupport_BTT.lua from Better Tech Tree version 1.0");
-- ===========================================================================
-- Better Tech Tree
-- Author: Infixo
-- 2018-03-19: Created
-- ===========================================================================

-- Rise & Fall check
local bIsRiseFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
print("Rise & Fall", (bIsRiseFall and "YES" or "no"));


-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
BTT_BASE_PopulateUnlockablesForCivic = PopulateUnlockablesForCivic;
BTT_BASE_PopulateUnlockablesForTech = PopulateUnlockablesForTech;
--BTT_BASE_GetUnlockablesForCivic_Cached = GetUnlockablesForCivic_Cached;
--BTT_BASE_GetUnlockablesForTech_Cached = GetUnlockablesForTech_Cached;
--BTT_BASE_GetUnlockIcon = GetUnlockIcon;

-- ===========================================================================
-- DEBUG ROUTINES
-- ===========================================================================

-- debug output routine
function dprint(sStr,p1,p2,p3,p4,p5,p6)
	local sOutStr = sStr;
	if p1 ~= nil then sOutStr = sOutStr.." [1] "..tostring(p1); end
	if p2 ~= nil then sOutStr = sOutStr.." [2] "..tostring(p2); end
	if p3 ~= nil then sOutStr = sOutStr.." [3] "..tostring(p3); end
	if p4 ~= nil then sOutStr = sOutStr.." [4] "..tostring(p4); end
	if p5 ~= nil then sOutStr = sOutStr.." [5] "..tostring(p5); end
	if p6 ~= nil then sOutStr = sOutStr.." [6] "..tostring(p6); end
	print(Game:GetCurrentGameTurn().." "..sOutStr);
end

-- debug routine - prints a table (no recursion)
function dshowtable(tTable:table)
	for k,v in pairs(tTable) do
		print(k, type(v), tostring(v));
	end
end

-- debug routine - prints a table, and tables inside recursively (up to 5 levels)
function dshowrectable(tTable:table, iLevel:number)
	local level:number = 0;
	if iLevel ~= nil then level = iLevel; end
	for k,v in pairs(tTable) do
		print(string.rep("---:",level), k, type(v), tostring(v));
		if type(v) == "table" and level < 5 then dshowrectable(v, level+1); end
	end
end


-- ===========================================================================
-- DATA AND HELPERS
-- ===========================================================================

local m_kExtraUnlockables:table = {}; -- simple table, each value is data for 1 extra unlock


-- filter out the unlockables for a specific tech or civic
function GetExtraUnlockables(sType:string)
	local tExtras:table = {};
	for _,item in ipairs(m_kExtraUnlockables) do
		if item.Type == sType then table.insert(tExtras, item); end
	end
	--print("found", #tExtras, "for", sType)
	return tExtras;
end

function AddExtraUnlockable(sType:string, sUnlockKind:string, sUnlockType:string, sDescription:string, sPediaKey:string)
	--dprint("FUN AddExtraUnlockable",sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
	local tItem:table = {
		Type = sType,
		UnlockKind = sUnlockKind, -- "BOOST", "IMPROVEMENT", "SPY", "HARVEST"
		UnlockType = sUnlockType, -- actual object to be shown
		Description = sDescription, -- additional info, to put on the icon OR into the tooltip
		PediaKey = sPediaKey,
	}
	table.insert(m_kExtraUnlockables, tItem);
end


-- ===========================================================================
--
-- ===========================================================================

local tBackgroundTextures:table = {
	BOOST_TECH = "ICON_BTT_BOOST_TECH", --"ICON_TECHUNLOCK_5", -- "LaunchBar_Hook_ScienceButton",
	BOOST_CIVIC = "ICON_BTT_BOOST_CIVIC", --"ICON_TECHUNLOCK_5", -- same as Resources "LaunchBar_Hook_CultureButton",
	HARVEST = "ICON_BTT_HARVEST",
	IMPR_BONUS = "ICON_BTT_IMPR_BONUS",
	UNIT = "ICON_BTT_UNIT",
};

-- NOT USED!!!
function GetUnlockIcon(typeName)
	if string.find(typeName, "TECH_") then return tBackgroundTextures.BOOST_TECH; end
	if string.find(typeName, "CIVIC_") then return tBackgroundTextures.BOOST_CIVIC; end
	return BTT_BASE_GetUnlockIcon(typeName);
end


-- this will add 1 simple unlockable, i.e. only background and icon
function PopulateUnlockableSimple(tItem:table, instanceManager:table)
	--dprint("FUN PopulateUnlockableSimple"); dshowtable(tItem);

	local unlockInstance = instanceManager:GetInstance();

	-- background is taken from Kind
	unlockInstance.UnlockIcon:SetTexture( IconManager:FindIconAtlas(tBackgroundTextures[tItem.UnlockKind], 38) );
	
	-- the actual icon is taken from Type
	unlockInstance.Icon:SetIcon("ICON_"..tItem.UnlockType);
	unlockInstance.Icon:SetHide(false);
	
	-- tooltip
	unlockInstance.UnlockIcon:SetToolTipString(tItem.Description);

	-- civilopedia
	if not IsTutorialRunning() and tItem.PediaKey then
		unlockInstance.UnlockIcon:RegisterCallback(
			Mouse.eRClick,
			function() LuaEvents.OpenCivilopedia(tItem.PediaKey);
		end);
	end

end


function PopulateUnlockablesForCivic(playerID:number, civicID:number, kItemIM:table, kGovernmentIM:table, callback:ifunction, hideDescriptionIcon:boolean )
	--dprint("FUN PopulateUnlockablesForCivic (pid,cid,bhide)",playerID,civicID,hideDescriptionIcon);
	
	local civicInfo:table = GameInfo.Civics[civicID];
	if civicInfo == nil then
		print("ERROR: PopulateUnlockablesForCivic Unable to find a civic type in the database with an ID value of", civicID);
		return;
	end
	
	local sCivicType:string = civicInfo.CivicType;
	local iNumIcons:number = 0;
	
	iNumIcons = BTT_BASE_PopulateUnlockablesForCivic(playerID, civicID, kItemIM, kGovernmentIM, callback, hideDescriptionIcon );
	if iNumIcons == nil then iNumIcons = 0; end
	
	--print("Adding additional icons for", sCivicType);
	
	for _,item in ipairs( GetExtraUnlockables(sCivicType) ) do
		PopulateUnlockableSimple(item, kItemIM);
		iNumIcons = iNumIcons + 1;
	end
	
	kItemIM.m_ParentControl:CalculateSize();
	
	return iNumIcons;
end


-- ===========================================================================
--
-- ===========================================================================
function PopulateUnlockablesForTech(playerID:number, techID:number, instanceManager:table, callback:ifunction )
	--dprint("FUN PopulateUnlockablesForTech (pid,tid)",playerID,techID);

	local techInfo:table = GameInfo.Technologies[techID];
	if techInfo == nil then
		print("ERROR: PopulateUnlockablesForTech Unable to find a tech type in the database with an ID value of", techID);
		return;
	end
	
	local sTechType:string = techInfo.TechnologyType;
	local iNumIcons:number = 0;
	
	iNumIcons = BTT_BASE_PopulateUnlockablesForTech(playerID, techID, instanceManager, callback);
	if iNumIcons == nil then iNumIcons = 0; end
	
	--print("Adding additional icons for", sTechType);
	
	for _,item in ipairs( GetExtraUnlockables(sTechType) ) do
		PopulateUnlockableSimple(item, instanceManager);
		iNumIcons = iNumIcons + 1;
	end
	
	instanceManager.m_ParentControl:CalculateSize();
	
	return iNumIcons;
end


-- need to plug into these so the orginal functions will know about new unlockables and e.g. extend the size of nodes
-- NOT USED!!!
function GetUnlockablesForCivic_Cached(civicType, playerId)
	dprint("FUN GetUnlockablesForCivic_Cached",civicType,playerId);
	-- get data from base function
	local results = BTT_BASE_GetUnlockablesForCivic_Cached(civicType, playerId);
	-- add our own
	for _,item in ipairs( GetExtraUnlockables(civicType) ) do
		-- for some reasons it remembers previous inserts?
		local bIsInserted:boolean = false;
		for _,res in ipairs(results) do if res[1] == item.UnlockType and res[2] == item.Description then bIsInserted = true; break; end end
		if not bIsInserted then
			print("inserting extra civic unlock", item.UnlockType, item.Description, item.PediaKey);
			table.insert(results, { item.UnlockType, item.Description, item.PediaKey });
		end
	end
	if civicType == "CIVIC_DIPLOMATIC_SERVICE" or civicType == "CIVIC_NATURAL_HISTORY" or civicType == "CIVIC_MOBILIZATION" or civicType == "CIVIC_CONSERVATION" then print(civicType); dshowrectable(results); end
	return results;
end

-- NOT USED!!!
function GetUnlockablesForTech_Cached(techType, playerId)
	dprint("FUN GetUnlockablesForTech_Cached",techType,playerId);
	-- get data from base function
	local results = BTT_BASE_GetUnlockablesForTech_Cached(techType, playerId);
	-- add our own
	for _,item in ipairs( GetExtraUnlockables(techType) ) do
		-- for some reasons it remembers previous inserts?
		local bIsInserted:boolean = false;
		for _,res in ipairs(results) do if res[1] == item.UnlockType and res[2] == item.Description then bIsInserted = true; break; end end
		if not bIsInserted then
			print("inserting extra tech unlock", item.UnlockType, item.Description, item.PediaKey);
			table.insert(results, { item.UnlockType, item.Description, item.PediaKey });
		end
	end
	return results;
end


-- ===========================================================================
-- POPULATE EXTRA UNLOCKABLES
-- ===========================================================================

-- simple version first, only for direct Civic/Tech boosts
-- TODO: add support for Units, Districts and Buildings
function PopulateBoosts()
	local sType:string, sUnlockKind:string, sUnlockType:string, sDescription:string, sDescBoost:string, sPediaKey:string, objectInfo:table;
	
	for row in GameInfo.Boosts() do
		-- what is boosted?
		if     row.TechnologyType then
			sUnlockKind = "BOOST_TECH"; sUnlockType = row.TechnologyType; sPediaKey = row.TechnologyType;
			sDescBoost = ": "..Locale.Lookup("LOC_BTT_BOOST_TECH_DESC", Locale.Lookup(GameInfo.Technologies[row.TechnologyType].Name), row.Boost);
		elseif row.CivicType then
			sUnlockKind = "BOOST_CIVIC"; sUnlockType = row.CivicType; sPediaKey = row.CivicType;
			sDescBoost = ": "..Locale.Lookup("LOC_BTT_BOOST_CIVIC_DESC", Locale.Lookup(GameInfo.Civics[row.CivicType].Name), row.Boost);
		else
			-- error in boost definition
		end
		-- what is the boost? it gives Type; in rare cases can generate more than 1 unlock!
		if row.BoostingCivicType then
			sType = row.BoostingCivicType;
			sDescription = Locale.Lookup( GameInfo.Civics[sType].Name )..sDescBoost;
			AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
		end
		if row.BoostingTechType then
			sType = row.BoostingTechType;
			sDescription = Locale.Lookup( GameInfo.Technologies[sType].Name )..sDescBoost;
			AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
		end
		if row.DistrictType then
			sType = nil; sDescription = sDescBoost;
			objectInfo = GameInfo.Districts[row.DistrictType];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				if row.BoostClass == "BOOST_TRIGGER_HAVE_X_DISTRICTS" then sDescription = string.format(" (%d)", row.NumItems)..sDescription; end
				sDescription = Locale.Lookup(objectInfo.Name)..sDescription;
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
		if row.BuildingType then
			sType = nil; sDescription = sDescBoost;
			objectInfo = GameInfo.Buildings[row.BuildingType];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				if row.BoostClass == "BOOST_TRIGGER_HAVE_X_BUILDINGS" then sDescription = string.format(" (%d)", row.NumItems)..sDescription; end
				sDescription = Locale.Lookup(objectInfo.Name)..sDescription;
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
		if row.Unit1Type then
			sType = nil; sDescription = sDescBoost;
			objectInfo = GameInfo.Units[row.Unit1Type];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				if row.BoostClass == "BOOST_TRIGGER_OWN_X_UNITS_OF_TYPE" or row.BoostClass == "BOOST_TRIGGER_MAINTAIN_X_TRADE_ROUTES" then sDescription = string.format(" (%d)", row.NumItems)..sDescription; end
				sDescription = Locale.Lookup(objectInfo.Name)..sDescription;
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
		if row.ResourceType then
			sType = nil; sDescription = sDescBoost;
			objectInfo = GameInfo.Resources[row.ResourceType];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				sDescription = Locale.Lookup(objectInfo.Name).."[ICON_"..row.ResourceType.."]"..sDescription;
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
		if row.ImprovementType and row.ResourceType == nil then
			sType = nil; sDescription = sDescBoost;
			objectInfo = GameInfo.Improvements[row.ImprovementType];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				if row.BoostClass == "BOOST_TRIGGER_HAVE_X_IMPROVEMENTS" then sDescription = string.format(" (%d)", row.NumItems)..sDescription; end
				sDescription = Locale.Lookup(objectInfo.Name)..sDescription;
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
	end
end

function PopulateHarvests()
	local sDesc:string;
	for row in GameInfo.Resource_Harvests() do
		sDesc = Locale.Lookup("LOC_UNITOPERATION_HARVEST_RESOURCE_DESCRIPTION")..": "..Locale.Lookup(GameInfo.Resources[row.ResourceType].Name)..string.format("[ICON_%s] %+d ", row.ResourceType, row.Amount)..GameInfo.Yields[row.YieldType].IconString;
		AddExtraUnlockable(row.PrereqTech, "HARVEST", row.ResourceType, sDesc, row.ResourceType);
	end
end

function PopulateImprovementBonus()
	local sType:string, sDesc:string;
	for row in GameInfo.Improvement_BonusYieldChanges() do
		if     row.PrereqTech  then sType = row.PrereqTech;
		elseif row.PrereqCivic then sType = row.PrereqCivic;
		else -- error in configuration
		end
		sDesc = Locale.Lookup(GameInfo.Improvements[row.ImprovementType].Name)..": +"..tostring(row.BonusYieldChange)..GameInfo.Yields[row.YieldType].IconString;
		AddExtraUnlockable(sType, "IMPR_BONUS", row.ImprovementType, sDesc, row.ImprovementType);
	end
end

function PopulateFromModifiers(sTreeKind:string)
	local sDesc:string;
	for row in GameInfo[sTreeKind.."Modifiers"]() do
		for mod in GameInfo.Modifiers() do
			if mod.ModifierId == row.ModifierId then
				if mod.ModifierType == "MODIFIER_PLAYER_GRANT_SPY" then
					sDesc = "+1 "..Locale.Lookup(GameInfo.Units["UNIT_SPY"].Name);
					AddExtraUnlockable(row[sTreeKind.."Type"], "UNIT", "UNIT_SPY", sDesc, "UNIT_SPY");
				else
					-- check for other modifiers here
				end
				break;
			end
		end
	end
end

function Initialize_BTT_TechTree()
	--dprint("FUN Initialize_BTT_TechTree()");
	-- add all the new init stuff here
	PopulateBoosts();
	PopulateHarvests();
	PopulateImprovementBonus();
	PopulateFromModifiers("Technology");
	print("Extra unlockables found:", #m_kExtraUnlockables);
end


function Initialize_BTT_CivicsTree()
	--dprint("FUN Initialize_BTT_CivicsTree()");
	-- add all the new init stuff here
	PopulateBoosts();
	PopulateImprovementBonus();
	PopulateFromModifiers("Civic");
	print("Extra unlockables found:", #m_kExtraUnlockables);
end

print("OK loaded TechAndCivicSupport_BTT.lua from Better Tech Tree");