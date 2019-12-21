--[[
-------------------------------------------------------------------------------
-- Autobanker, made by r4cken
-------------------------------------------------------------------------------
This software is under : CreativeCommons CC BY-NC-SA 4.0
Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

You are free to:

    Share — copy and redistribute the material in any medium or format
    Adapt — remix, transform, and build upon the material
    The licensor cannot revoke these freedoms as long as you follow the license terms.


Under the following terms:

    Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
    NonCommercial — You may not use the material for commercial purposes.
    ShareAlike — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
    No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.


Please read full licence at : 
http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode

This AddOn has taken inspiration and small snippets from Dustman by Ayantir, Garkin & iFedix
]]

-- The namespace for Autobanker, top-level table
if Autobanker == nil then Autobanker = {} end
local AB = Autobanker
if not AB.libsProperlyLoaded then return end

AB.predicates = {}
AB.filters = {}
AB.helpers = {}

local predicates = AB.predicates
local filters = AB.filters
local helpers = AB.helpers

--
-- HELPER Functions
--
function helpers.GetHouseBankBag()
	if IsBankOpen() then 
	  if IsHouseBankBag(GetBankingBag()) then
		  return GetBankingBag()
	  end
	else 
	  return nil
	end
end

-- this function returns more info than desired, but it's for the exemple.
function helpers.StackInfoInBag(sourceBag, slotIndex, targetBag, itemLink)
	local stackCountBackpack, stackCountBank
	
	if not AB.QtyBagCache[itemLink] then
			stackCountBackpack, stackCountBank = GetItemLinkStacks(itemLink) -- Not updated in realtime
			AB.QtyBagCache[itemLink] = {}
			AB.QtyBagCache[itemLink][BAG_BACKPACK] = stackCountBackpack
			AB.QtyBagCache[itemLink][BAG_BANK] = stackCountBank
			AB.QtyBagCache[itemLink][BAG_SUBSCRIBER_BANK] = AB.QtyBagCache[itemLink][BAG_BANK]
	else
			stackCountBackpack = AB.QtyBagCache[itemLink][BAG_BACKPACK]
			stackCountBank = AB.QtyBagCache[itemLink][BAG_BANK]
	end
	
	--[[d("--------------")
	d(stackCountBackpack, stackCountBank)
	d("---")
	d(GetItemLinkStacks(itemLink))
	d("--------------")
  ]]
  
	local stackSize, maxStack = GetSlotStackSize(sourceBag, slotIndex)
	if targetBag == BAG_BACKPACK then
		return stackSize, maxStack, stackCountBackpack, stackCountBank
	elseif targetBag == BAG_BANK or targetBag == BAG_SUBSCRIBER_BANK then
		return stackSize, maxStack, stackCountBackpack, stackCountBank
	end
end

--
-- PREDICATE FUNCTIONS AND FILTERING
--
function predicates.IsItemCharacterBound(itemLink)
	local bindType = GetItemLinkBindType(itemLink)
  local isBound = IsItemLinkBound(itemLink)
  return isBound and bindType == BIND_TYPE_ON_PICKUP_BACKPACK
end

function predicates.IsItemRightType(itemType)
	return AB.GetSettings().typesToDeposit[itemType]
end

function predicates.IsItemTypeIntricate(itemTrait)
	return AB.GetSettings().shouldDepositIntricate and AB.GetSettings().intricateType[itemTrait]
end

function predicates.IsItemResearchable(itemLink)
	local _, isItemResearchable = AB.LR:GetItemTraitResearchabilityInfo(itemLink)
	return AB.GetSettings().shouldDepositResearchable and isItemResearchable
end

function predicates.IsItemSurveyReport(itemType, specializedItemType)
	return AB.GetSettings().shouldDepositSurveyReport and (itemType == ITEMTYPE_TROPHY and specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT )
end

function predicates.IsItemTreasureMap (itemType, specializedItemType)
	return AB.GetSettings().shouldDepositTreasureMap and (itemType == ITEMTYPE_TROPHY and specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP)
end
		
function predicates.DoesItemMeetConditions(itemType, specializedItemType, itemTrait, itemLink)
    return 
    predicates.IsItemRightType(itemType) or 
		predicates.IsItemTypeIntricate(itemTrait) or 
		predicates.IsItemResearchable(itemLink) or 
		predicates.IsItemSurveyReport(itemType, specializedItemType) or 
		predicates.IsItemTreasureMap(itemType, specializedItemType)
end

-- SHARED_INVENTORY:GenerateFullSlotData(predicate, ...)
--  PREDICATE
function filters.RemoveUnwantedItems(itemData)
    local itemType, specializedItemType = GetItemType(BAG_BACKPACK, itemData.slotIndex)
    local itemTrait = GetItemTrait(BAG_BACKPACK, itemData.slotIndex)
    local itemLink = GetItemLink(BAG_BACKPACK, itemData.slotIndex)

    local itsBound = predicates.IsItemCharacterBound(itemLink)
    local itsStolen = itemData.stolen
    local itsJunk = itemData.isJunk
    local itsProtected = itemData.isPlayerLocked
    local itsStackCount = itemData.stackCount

    if itsBound or itsStolen or itsJunk or itsProtected or itsStackCount < 1 then
        -- filter out this item from the resulting table of items
        return false
    elseif predicates.DoesItemMeetConditions(itemType, specializedItemType, itemTrait, itemLink) == false then
        return false
    else
        return true
    end
end

function filters.KeepOnlyIncompleteStacks(itemData)
  local itemLink = GetItemLink(itemData.bagId, itemData.slotIndex)
  if not IsItemLinkStackable(itemLink) then return false end
  local stackSize, maxStack, stackCountBackpack, stackCountBank = helpers.StackInfoInBag(itemData.bagId, itemData.slotIndex, itemData.bagId, itemLink)
  if stackSize > maxStack then return false end
  return true
end

-- ADDON CHAT OUTPUT
--
function AB.Print(message)
	CHAT_SYSTEM:AddMessage(message)
end
  
function AB.PrintItemDeposited(itemLink, stackCount)
  if AB.GetSettings().notifications.deposit then
    AB.Print(zo_strformat(GetString(AB_TRANSACTION_FORMAT), itemLink), stackCount)
  end
end
  
function AB.PrintNItemsDeposited(nItemsDeposited)
  if AB.GetSettings().notifications.amount then
    AB.Print(zo_strformat(GetString(AB_COUNT_FORMAT), nItemsDeposited))
  end
end
