-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- ItemManager.setCustomCharAdd(onCharItemAdd);
end

function updateEncumbrance(nodeChar)
	-- local nEncTotal = 0;

	-- local nCount, nWeight;
	-- for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		-- if DB.getValue(vNode, "carried", 0) ~= 0 then
			-- nCount = DB.getValue(vNode, "count", 0);
			-- if nCount < 1 then
				-- nCount = 1;
			-- end
			-- nWeight = DB.getValue(vNode, "weight", 0);
			
			-- nEncTotal = nEncTotal + (nCount * nWeight);
		-- end
	-- end

	-- DB.setValue(nodeChar, "encumbrance.load", "number", nEncTotal);
end

function onCharItemAdd(nodeItem)
	-- DB.setValue(nodeItem, "carried", "number", 1);
end

--
-- weapon management
--
function getWeaponAttackRollStructures(nodeWeapon)
	if not nodeWeapon then
		return;
	end
	
	local nodeChar = nodeWeapon.getChild("...");
	local rActor = ActorManager.getActor("pc", nodeChar);

	--create attack object
	local rAttack = {};
	rAttack.type = "attack";
	rAttack.label = DB.getValue(nodeWeapon, "name", "");
	
	-- effects (weapon + enhancements if any)
	rAttack.effects = DB.getValue(nodeWeapon, "effects", "");
	if rAttack.effects ~= "" then
		rAttack.effects = (rAttack.effects).."\n";
	end
	local aEnhancementNodes = UtilityManager.getSortedTable(DB.getChildren(nodeWeapon, "enhancementlist"));
	for _,v in ipairs(aEnhancementNodes) do
		local sEffect = DB.getValue(v, "effect", "");
		if sEffect ~= "" then
			local sName = DB.getValue(v, "name", "");
			if sName ~= "" then
				rAttack.effects = (rAttack.effects).."["..sName.."] : "..(sEffect).."\n";
			else
				rAttack.effects = (rAttack.effects).."[Enhancement] : "..(sEffect).."\n";
			end
		end
	end
	
	-- melee (M) / range (R)
	local nType = DB.getValue(nodeWeapon, "type", 0);
	if nType == 2 then
		rAttack.range = "M";
		rAttack.cm = true;
	elseif nType == 1 then
		rAttack.range = "R";
	else
		rAttack.range = "M";
	end
	
	rAttack.errorMsg = "";
	-- stat
	rAttack.stat = DB.getValue(nodeWeapon, "attackstat", "");
	if rAttack.stat == "" then
		rAttack.errorMsg = "No stat defined for attack roll. \n";
	end
	-- skill
	rAttack.skill = DB.getValue(nodeWeapon, "attackskill", "");
	if rAttack.skill == "" then
		rAttack.errorMsg = rAttack.errorMsg.."No skill defined for attack roll.\n";
	end
	-- wa
	rAttack.weaponaccuracy = DB.getValue(nodeWeapon, "weapon_accuracy", 0);
	
	return rActor, rAttack;
end

function getWeaponDefenseRollStructures(nodeWeapon)
	if not nodeWeapon then
		return;
	end
	
	local nodeChar = nodeWeapon.getChild("...");
	local rActor = ActorManager.getActor("pc", nodeChar);

	--create attack object
	local rAttack = {};
	rAttack.type = "defense";
	rAttack.label = DB.getValue(nodeWeapon, "name", "");
	
	-- effects (weapon + enhancements if any)
	rAttack.effects = DB.getValue(nodeWeapon, "effects", "");
	if rAttack.effects ~= "" then
		rAttack.effects = (rAttack.effects).."\n";
	end
	local aEnhancementNodes = UtilityManager.getSortedTable(DB.getChildren(nodeWeapon, "enhancementlist"));
	for _,v in ipairs(aEnhancementNodes) do
		local sEffect = DB.getValue(v, "effect", "");
		if sEffect ~= "" then
			local sName = DB.getValue(v, "name", "");
			if sName ~= "" then
				rAttack.effects = (rAttack.effects).."["..sName.."] : "..(sEffect).."\n";
			else
				rAttack.effects = (rAttack.effects).."[Enhancement] : "..(sEffect).."\n";
			end
		end
	end
	
	-- melee (M) / range (R)
	local nType = DB.getValue(nodeWeapon, "type", 0);
	if nType == 2 then
		rAttack.range = "M";
		rAttack.cm = true;
	elseif nType == 1 then
		rAttack.range = "R";
	else
		rAttack.range = "M";
	end
	
	rAttack.errorMsg = "";
	-- stat
	rAttack.stat = DB.getValue(nodeWeapon, "attackstat", "");
	if rAttack.stat == "" then
		rAttack.errorMsg = "No stat defined for attack roll. \n";
	end
	-- skill
	rAttack.skill = DB.getValue(nodeWeapon, "attackskill", "");
	if rAttack.skill == "" then
		rAttack.errorMsg = rAttack.errorMsg.."No skill defined for attack roll.\n";
	end
	-- wa
	rAttack.weaponaccuracy = DB.getValue(nodeWeapon, "weapon_accuracy", 0);
	
	return rActor, rAttack;
end

-- get character and damage info for damage roll
-- param :
--	* nodeWeapon : dbNode for source weapon
-- returns : 
--	* rActor	 : actor info retrieved by using ActorManager.resolveActor
--	* rDamage	 : object containing all needed info to resolve damage (range, type, label, clauses)
function getWeaponDamageRollStructures(nodeWeapon)
	-- Retreive rActor
	local nodeChar = nodeWeapon.getChild("...");
	local rActor = ActorManager.getActor("pc", nodeChar);
	
	-- construct rDamage
	local rDamage = {};
	
	-- range or melee
	local bRanged = (DB.getValue(nodeWeapon, "type", 0) == 1);
	if bRanged then
		rDamage.range = "R";
	else
		rDamage.range = "M";
	end

	rDamage.type = "damage";
	rDamage.label = DB.getValue(nodeWeapon, "name", "");
	
	-- compile all weapon damage entries
	rDamage.clauses = {};
	local aDamageNodes = UtilityManager.getSortedTable(DB.getChildren(nodeWeapon, "damagelist"));
	for _,v in ipairs(aDamageNodes) do
		local sDmgType = DB.getValue(v, "type", "");
		local aDmgDice = DB.getValue(v, "dice", {});
		local nDmgMod = DB.getValue(v, "bonus", 0);
		
		local sDmgAbility = DB.getValue(v, "dmgbonusstat", "");
		if sDmgAbility == "meleebonusdamage" then
			nDmgMod = nDmgMod + DB.getValue(nodeChar, "attributs.meleebonusdamage", 0);
		elseif sDmgAbility == "punch" or sDmgAbility == "kick" then
			-- todo
		end
		
		table.insert(rDamage.clauses, {	dice = aDmgDice, 
										modifier = nDmgMod, 
										stat = sDmgAbility, 
										dmgtype = sDmgType, });
	end
	
	return rActor, rDamage;
end

-- get character and damage info for damage roll
-- param :
--	* nodeChar	: dbNode for character
--  * sType		: "punch" or "kick"
-- returns : 
--	* rActor	: actor info retrieved by using ActorManager.resolveActor
--	* rDamage	: object containing all needed info to resolve damage (range, type, label, clauses)
function getUnarmedDamageRollStructures(nodeChar, sType)
	-- Retreive rActor
	local rActor = ActorManager.getActor("pc", nodeChar);
	
	-- construct rDamage
	local rDamage = {};
	
	-- range or melee
	rDamage.range = "M";
	
	rDamage.type = "damage";
	rDamage.label = sType;
	
	-- compile all weapon damage entries
	rDamage.clauses = {};
	
	local unarmedNode = DB.getValue(nodeChar, "attributs."..sType, "");
	
	local sDmgType = "";
	local aDmgDice = DB.getValue(nodeChar, "attributs."..sType, "");
	local nDmgMod = DB.getValue(nodeChar, "attributs."..sType.."_modifier", 0);
	
	table.insert(rDamage.clauses, {	dice = aDmgDice, 
									modifier = nDmgMod, 
									stat = "", 
									dmgtype = sDmgType, });
	
	return rActor, rDamage;
end
