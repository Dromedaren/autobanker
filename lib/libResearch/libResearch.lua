-- This version of libResearch uses item links instead of inventory coordinates.
local MAJOR, MINOR = "libResearch-2", 2
local libResearch, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not libResearch then return end	--the same or newer version of this lib is already loaded into memory 
--thanks to Seerah for the previous lines and library

local BLACKSMITH = CRAFTING_TYPE_BLACKSMITHING
local CLOTHIER = CRAFTING_TYPE_CLOTHIER
local WOODWORK = CRAFTING_TYPE_WOODWORKING

local researchMap = {
	[BLACKSMITH] = {
		WEAPON = {
			[WEAPONTYPE_AXE] = 1,
			[WEAPONTYPE_HAMMER] = 2,
			[WEAPONTYPE_SWORD] = 3,
			[WEAPONTYPE_TWO_HANDED_AXE] = 4,
			[WEAPONTYPE_TWO_HANDED_HAMMER] = 5,
			[WEAPONTYPE_TWO_HANDED_SWORD] = 6,
			[WEAPONTYPE_DAGGER] = 7
		},
		ARMOR = {
			[EQUIP_TYPE_CHEST] = 8,
			[EQUIP_TYPE_FEET] = 9,
			[EQUIP_TYPE_HAND] = 10,
			[EQUIP_TYPE_HEAD] = 11,
			[EQUIP_TYPE_LEGS] = 12,
			[EQUIP_TYPE_SHOULDERS] = 13,
			[EQUIP_TYPE_WAIST] = 14
		}
	},

	--normal for light, +7 for medium
	[CLOTHIER] = {
		ARMOR =  {
			[EQUIP_TYPE_CHEST] = 1,
			[EQUIP_TYPE_FEET] = 2,
			[EQUIP_TYPE_HAND] = 3,
			[EQUIP_TYPE_HEAD] = 4,
			[EQUIP_TYPE_LEGS] = 5,
			[EQUIP_TYPE_SHOULDERS] = 6,
			[EQUIP_TYPE_WAIST] = 7
		}
	},

	[WOODWORK] = {
		WEAPON = {
			[WEAPONTYPE_BOW] = 1,
			[WEAPONTYPE_FIRE_STAFF] = 2,
			[WEAPONTYPE_FROST_STAFF] = 3,
			[WEAPONTYPE_LIGHTNING_STAFF] = 4,
			[WEAPONTYPE_HEALING_STAFF] = 5
		},
		ARMOR = {
			[EQUIP_TYPE_OFF_HAND] = 6
		}
	},
}

-- returns true if the character knows or is in the process of researching the supplied trait; else returns false
-- there are a few items, given to the character at the very beginning of the game, that are traited but unresearchable
-- these will present bugs when used with this function
function libResearch:WillCharacterKnowTrait(craftingSkillType, researchLineIndex, traitIndex)
	local _, _, knows = GetSmithingResearchLineTraitInfo(craftingSkillType, researchLineIndex, traitIndex)
	if knows then return true end
	local willKnow = GetSmithingResearchLineTraitTimes(craftingSkillType, researchLineIndex, traitIndex)
	if willKnow ~= nil then return true end
	return false
end

-- returns int traitKey, bool isResearchable, string reason
-- traitKey will be 0 if item is ornate, intricate, or traitless
-- if isResearchable, then reason will be nil
-- otherwise, reason will be: "WrongItemType", "Ornate", "Intricate", "Traitless", "AlreadyKnown" 
function libResearch:GetItemTraitResearchabilityInfo(itemLink)
	local itemType = GetItemLinkItemType(itemLink)
	if itemType ~= ITEMTYPE_ARMOR and itemType ~= ITEMTYPE_WEAPON then
		return 0, false, "WrongItemType"
	end
	
	local craftingSkillType, researchLineIndex, traitIndex = self:GetItemResearchInfo(itemLink)
	-- do this first to catch jewelry
	if (traitIndex == "Ornate") or (traitIndex == "Intricate") then
		return 0, false, traitIndex
	end
	if researchLineIndex == -1 or craftingSkillType == -1 then
		return 0, false, "WrongItemType"
	elseif traitIndex == -1 then
		return 0, false, "Traitless"
	end
	if (self:WillCharacterKnowTrait(craftingSkillType, researchLineIndex, traitIndex)) then
		return self:GetTraitKey(craftingSkillType, researchLineIndex, traitIndex), false, "AlreadyKnown"
	else
		return self:GetTraitKey(craftingSkillType, researchLineIndex, traitIndex), true
	end
end

-- returns a trait key that is unique per researchable trait
function libResearch:GetTraitKey( craftingSkillType, researchLineIndex, traitIndex )
	return craftingSkillType * 10000 + researchLineIndex * 100 + traitIndex
end

-- returns the global enums CRAFTING_TYPE_BLACKSMITHING, CRAFTING_TYPE_CLOTHIER, or CRAFTING_TYPE_WOODWORKING
-- if applicable; else return -1
function libResearch:GetItemCraftingSkill( itemLink )
	local itemType = GetItemLinkItemType(itemLink)
	if itemType == ITEMTYPE_ARMOR then
		local armorType = GetItemLinkArmorType(itemLink)
		if armorType == ARMORTYPE_HEAVY then
			return BLACKSMITH
		elseif armorType == ARMORTYPE_LIGHT or armorType == ARMORTYPE_MEDIUM then
			return CLOTHIER
		else
			return -1
		end
	elseif itemType == ITEMTYPE_WEAPON then
		local weaponType = GetItemLinkWeaponType(itemLink)
		if (weaponType == WEAPONTYPE_BOW) or
			(weaponType == WEAPONTYPE_FIRE_STAFF) or
			(weaponType == WEAPONTYPE_FROST_STAFF) or
			(weaponType == WEAPONTYPE_HEALING_STAFF) or
			(weaponType == WEAPONTYPE_LIGHTNING_STAFF) or
			(weaponType == WEAPONTYPE_SHIELD) then
			return WOODWORK
		elseif (weaponType ~= WEAPONTYPE_NONE) and (weaponType ~= WEAPONTYPE_RUNE) then
			return BLACKSMITH
		else
			return -1
		end
	end
    return -1
end

-- returns a trait index suitable for feeding to the global functions GetSmithingLineTraitInfo() et. al.
-- or returns -1 if no trait exists
function libResearch:GetResearchTraitIndex( itemLink )
	local traitIndex = GetItemLinkTraitInfo(itemLink)

	if(traitIndex == ITEM_TRAIT_TYPE_ARMOR_ORNATE or traitIndex == ITEM_TRAIT_TYPE_WEAPON_ORNATE or traitIndex == ITEM_TRAIT_TYPE_JEWELRY_ORNATE) then
		return "Ornate"
	elseif(traitIndex == ITEM_TRAIT_TYPE_ARMOR_INTRICATE or traitIndex == ITEM_TRAIT_TYPE_WEAPON_INTRICATE or traitIndex == ITEM_TRAIT_TYPE_JEWELRY_INTRICATE) then
		return "Intricate"
	end

	if (traitIndex == ITEM_TRAIT_TYPE_ARMOR_NIRNHONED) or (traitIndex == ITEM_TRAIT_TYPE_WEAPON_NIRNHONED) then
		return 9
	end
	--this used to be "if(itemType == ITEMTYPE_ARMOR)", but shields are not armor even though they are armor
	if(traitIndex > 10) then
		traitIndex = traitIndex - 10;
	end

	if(not (traitIndex >= 1 and traitIndex <=8)) then
		return -1
	end

	return traitIndex
end

-- returns an index that corresponds to the weapon or armor type within the given crafting skill
-- or returns -1 if not applicable
function libResearch:GetResearchLineIndex( itemLink )
	local craftingSkillType = libResearch:GetItemCraftingSkill(itemLink)
	local armorType = GetItemLinkArmorType(itemLink)
	local equipType = GetItemLinkEquipType(itemLink)
	local weaponType = GetItemLinkWeaponType(itemLink)

	if(craftingSkillType ~= BLACKSMITH and craftingSkillType ~= WOODWORK and craftingSkillType ~= CLOTHIER) then
		return -1
	end

	local researchLineIndex
	--if is armor
	if(armorType ~= ARMORTYPE_NONE or weaponType == WEAPONTYPE_SHIELD) then
		researchLineIndex = researchMap[craftingSkillType].ARMOR[equipType]
		if(armorType == ARMORTYPE_MEDIUM) then
			researchLineIndex = researchLineIndex + 7
		end
	--else is weapon or nothing
	else
		--check if actually is weapon first
		if(weaponType == WEAPONTYPE_NONE) then
			return -1
		end
		researchLineIndex = researchMap[craftingSkillType].WEAPON[weaponType]
	end

	return researchLineIndex or -1
end

-- returns craftingSkill, researchLineIndex, traitIndex for the given item link
function libResearch:GetItemResearchInfo( itemLink )
	return self:GetItemCraftingSkill(itemLink), self:GetResearchLineIndex(itemLink), self:GetResearchTraitIndex(itemLink)
end

-- returns true if the craftingSkillType is one of the researchable crafts, false otherwise
function libResearch:IsBigThreeCrafting( craftingSkillType )
	if(craftingSkillType == BLACKSMITH or craftingSkillType == CLOTHIER or craftingSkillType == WOODWORK) then
		return true
	end
	return false
end

function libResearch:GetResearchMap()
	return researchMap
end