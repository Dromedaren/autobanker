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

-- Local store the event manager
local em = GetEventManager()
local _


-- Dependencies
local LR = LibStub("libResearch-2")
local autobankerInitializeColor = "EFFBBEA"

-- Create the namespace for AB, top-level table
if not AB then AB = {} end

-- AddOn information
AB.name = "Autobanker"
AB.version = "1.6"
AB.author = "r4cken"
AB.website = "https://www.esoui.com/downloads/info2199-AutobankerAutomaticallydeposititems.html"

-- Holds our SavedVariable data
AB.savedVars = {}

-- Default values for saved vars
local defaults = {
  worldname = GetWorldName(),
  -- Manual or Automatic deposits
  automaticTransfers = false,
  useGlobalSettings = false,
	typesToDeposit = {
		[ITEMTYPE_SOUL_GEM] = false,
		[ITEMTYPE_TOOL] = false,
		[ITEMTYPE_POTION_BASE] = false,
		[ITEMTYPE_POISON_BASE] = false,
		[ITEMTYPE_INGREDIENT] = false,
		[ITEMTYPE_STYLE_MATERIAL] = false,
		[ITEMTYPE_FOOD] = false,
		[ITEMTYPE_DRINK] = false,
		[ITEMTYPE_TREASURE] = false,
		[ITEMTYPE_FURNISHING_MATERIAL] = false,
		[ITEMTYPE_RECIPE] = false,
		[ITEMTYPE_MASTER_WRIT] = false,
		[ITEMTYPE_POTION] = false,
		[ITEMTYPE_POISON] = false,
	},
  -- Toggles depositing all intricate types
  shouldDepositIntricate = false,
  -- Specific categories
  intricateType = {
    [ITEM_TRAIT_TYPE_ARMOR_INTRICATE] = false,
    [ITEM_TRAIT_TYPE_WEAPON_INTRICATE] = false,
    [ITEM_TRAIT_TYPE_JEWELRY_INTRICATE] = false,
  },
  shouldDepositTreasureMap = false,
  shouldDepositSurveyReport = false,
  shouldDepositResearchable = false,
  -- Notifications
  notifications = {
	deposit = true,
	amount = true,
  },
  -- Currencies
  CURRENCY_DATA =
  {
	[CURT_MONEY] =
	{
	  minimum = 5000,
	  deposit = true,
	  slider = { max = 200000, step = 1000 },
	},
	[CURT_ALLIANCE_POINTS] =
	{
	  minimum = 10000,
	  deposit = true,
	  slider = { max = 1000000, step = 5000 },
	},
	[CURT_TELVAR_STONES] =
	{
	  minimum = 300,
	  deposit = true,
	  slider = { max = 60000, step = 300 },
	},
	[CURT_WRIT_VOUCHERS] =
	{
	  minimum = 0,
	  deposit = true,
	  slider = { max = 1000, step = 10 },
	},
  }
}

-- Make a bag cache to to find empty slots
AB.ourBagCache = {
	[BAG_BANK] = {},
	[BAG_SUBSCRIBER_BANK] = {},
}


-- BAG FUNCTION
local function FindEmptySlotInBag(targetBag)
	for slotIndex = 0, (GetBagSize(targetBag) - 1) do
		if not SHARED_INVENTORY.bagCache[targetBag][slotIndex] and not AB.ourBagCache[targetBag][slotIndex] then
			AB.ourBagCache[targetBag][slotIndex] = true
			return slotIndex
		end
	end
	return nil
end

-- Predicate function for 
-- SHARED_INVENTORY:GenerateFullSlotData(predicate, ...) 
-- where ... is a variable argument of bags to combine for the bag data


local function FilterUnwantedItems(itemData)
    local isStolen = itemData.stolen
    local isJunk = itemData.isJunk
    local isProtected = itemData.isPlayerLocked
    if isStolen or isJunk or isProtected then
      return false
    else
      return true
    end
end

-- ADDON CHAT OUTPUT
function AB.ABPrint(message)
	CHAT_SYSTEM:AddMessage(message)
end

-- PROTECTED FUNCTION
local function MoveItem(sourceBag, sourceSlot, targetBag, emptySlot, stackCount)
	if IsProtectedFunction("RequestMoveItem") then
		CallSecureProtected("RequestMoveItem", sourceBag, sourceSlot, targetBag, emptySlot, stackCount)
	else
		RequestMoveItem(sourceBag, sourceSlot, targetBag, emptySlot, stackCount)
	end
end

-- BAG FUNCTION
-- Handle finding an empty slot and consider ESO+ and those without it

function AB.TryPlaceItemInEmptySlot(sourceBag, sourceSlot, targetBag, stackCount)
	local emptySlot = FindEmptySlotInBag(targetBag)
	
	--[[ Special case handling ESO+ members because they actually 
         have access to two separate different bank bags!
	  ]]
	if not emptySlot and IsESOPlusSubscriber() then
		if targetBag == BAG_BANK then
			targetBag = BAG_SUBSCRIBER_BANK
			emptySlot = FindEmptySlotInBag(targetBag)
		elseif targetBag == BAG_SUBSCRIBER_BANK then
			targetBag = BAG_BANK
			emptySlot = FindEmptySlotInBag(targetBag)
		end
	end
	
	if emptySlot ~= nil then
		MoveItem(sourceBag, sourceSlot, targetBag, emptySlot, stackCount)
		if AB.GetSettings().notifications.deposit then
			AB.ABPrint(zo_strformat(GetString(AB_TRANSACTION_FORMAT), GetItemLink(sourceBag, sourceSlot), stackCount))
		end
		return true
	else 
		local errorStringId = SI_INVENTORY_ERROR_BANK_FULL
		ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.NEGATIVE_CLICK, errorStringId)
		return false
	end
end

--
-- PREDICATE FUNCTIONS AND FILTERING
-- Checks conditions in Autobanker

function AB.IsItemRightType(itemType)
	return AB.GetSettings().typesToDeposit[itemType]
end

function AB.IsItemTypeIntricate(itemTrait)
	return AB.GetSettings().shouldDepositIntricate and AB.GetSettings().intricateType[itemTrait]
end

function AB.IsItemResearchable(itemLink)
	local _, isItemResearchable = LR:GetItemTraitResearchabilityInfo(itemLink)
	if AB.GetSettings().shouldDepositResearchable and isItemResearchable then
		return true
	else
		return false
	end
end

function AB.IsItemSurveyReport(itemType, specializedItemType)
	return AB.GetSettings().shouldDepositSurveyReport and (itemType == ITEMTYPE_TROPHY and specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT )
end

function AB.IsItemTreasureMap(itemType, specializedItemType)
	return AB.GetSettings().shouldDepositTreasureMap and (itemType == ITEMTYPE_TROPHY and specializedItemType == SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP)
end

function AB.IsItemCharacterBound(itemLink)
	local bindType = GetItemLinkBindType(itemLink)
    local isBound = IsItemLinkBound(itemLink)
    return isBound and bindType == BIND_TYPE_ON_PICKUP_BACKPACK
end
		
function AB.ItemMeetsConditions(itemType, specializedItemType, itemTrait, itemLink)
	return AB.IsItemRightType(itemType) or AB.IsItemTypeIntricate(itemTrait) or AB.IsItemResearchable(itemLink) or AB.IsItemSurveyReport(itemType, specializedItemType) or AB.IsItemTreasureMap(itemType, specializedItemType)
end

function AB.GetCurrencyToDeposit(currencyType)
  local curr = AB.savedVars.CURRENCY_DATA[currencyType]
  if curr.deposit then
    local thisMuchOf = GetCarriedCurrencyAmount(currencyType) - curr.minimum
	if thisMuchOf > 0 then
	  local alertString = zo_strformat(SI_FIRST_SPECIAL_CURRENCY, GetString(AB_CURT_TRANSFER_FORMAT), ZO_Currency_FormatPlatform(currencyType, thisMuchOf, ZO_CURRENCY_FORMAT_AMOUNT_ICON))
	  AB.ABPrint(alertString)
	  DepositCurrencyIntoBank(currencyType, thisMuchOf)
	end
  end
end


--
-- EVENT
-- The main depositing function
local function TriggerAutobanker()
  local nItemsDeposited = 0
  local transactions = 0
  local bagCache = SHARED_INVENTORY:GenerateFullSlotData(FilterUnwantedItems, BAG_BACKPACK)
  
  for _ , data in pairs(bagCache) do
    if transactions < 50 then
      local itemLink = GetItemLink(BAG_BACKPACK, data.slotIndex)
      -- returns [ItemType]
      local itemType, specializedItemType = GetItemType(BAG_BACKPACK, data.slotIndex)
      -- local itemName = GetItemName(BAG_BACKPACK, data.slotIndex)
      -- returns [ItemTraitType]
      local itemTrait = GetItemTrait(BAG_BACKPACK, data.slotIndex) 
      if data.stackCount >= 1 then
        if AB.ItemMeetsConditions(itemType, specializedItemType, itemTrait, itemLink) and not AB.IsItemCharacterBound(itemLink) then
          if AB.TryPlaceItemInEmptySlot(BAG_BACKPACK, data.slotIndex, BAG_BANK, data.stackCount) then
            if (data.isJunk) then
              AB.ABPrint("True")
            end
            transactions = transactions + 1
            nItemsDeposited = nItemsDeposited + data.stackCount
          else
            break
          end
        end
      end
    end
  end
  
  if nItemsDeposited > 0 and AB.GetSettings().notifications.amount then
	AB.ABPrint(zo_strformat(GetString(AB_COUNT_FORMAT), nItemsDeposited))
  end
  
  for currencyType, _ in ipairs(defaults.CURRENCY_DATA) do
    AB.GetCurrencyToDeposit(currencyType)
  end
end


--
-- KEYBINDS
-- Autobanker button group on the keybindstrip
local autobankerKeybindButtonGroup =
{
  alignment = KEYBIND_STRIP_ALIGN_CENTER,
  {
    name = GetString(AB_TRIGGER_AUTOBANKER),
    keybind = "UI_SHORTCUT_QUATERNARY",
    callback = TriggerAutobanker,
  },
}

--
-- Bank scene BANK_FRAGMENT 
-- Enable Autobankers keybindstrip
local function AutobankerOnStateChanged(oldState, newState)
  if newState == SCENE_SHOWING then
	KEYBIND_STRIP:AddKeybindButtonGroup(autobankerKeybindButtonGroup)
  elseif newState == SCENE_HIDDEN then
	KEYBIND_STRIP:RemoveKeybindButtonGroup(autobankerKeybindButtonGroup)
  end
end

-- CALLBACK
-- Enable Manual Autobanking
local function EnableManualAutobanking()
  BANK_FRAGMENT:RegisterCallback("StateChange", AutobankerOnStateChanged)
  BACKPACK_BANK_LAYOUT_FRAGMENT:RegisterCallback("StateChange", AutobankerOnStateChanged)
  AB.ABPrint(zo_strformat("Enabling Manual Autobanking"))
end

-- CALLBACK
-- Disable Manual Autobanking
local function DisableManualAutobanking()
  BANK_FRAGMENT:UnregisterCallback("StateChange", AutobankerOnStateChanged)
  BACKPACK_BANK_LAYOUT_FRAGMENT:UnregisterCallback("StateChange", AutobankerOnStateChanged)
  AB.ABPrint(zo_strformat("Disabling Manual Autobanking"))
end

-- Toggle the usage of Autobanker automatic deposits.
function AB.ToggleManualOverride()
  if AB.savedVars.automaticTransfers then
	em:RegisterForEvent(AB.name, EVENT_OPEN_BANK, TriggerAutobanker)
	DisableManualAutobanking()
  else
    em:UnregisterForEvent(AB.name, EVENT_OPEN_BANK)
	EnableManualAutobanking()
  end
end

--
-- EVENT
-- AddOn PlayerActivated
local function OnPlayerActivated()
  em:UnregisterForEvent(AB.name, EVENT_PLAYER_ACTIVATED)
  -- Initialization message
  AB.ABPrint(zo_strformat("|c<<1>><<2>>|r", autobankerInitializeColor, GetString(AB_INIT)))
end


local function SetProfileSettings(characterId)

end
--
-- EVENT
-- AddOn Initialization
local function Initialize(event, addon)
  
	-- filter for just Autobanker addon event
	if addon ~= AB.name then return end
	em:UnregisterForEvent(AB.name, EVENT_ADD_ON_LOADED)
	-- Load saved variables
    AB.savedVars = ZO_SavedVars:NewCharacterIdSettings("AutobankerSavedVars", 4, nil, defaults)
	-- Make our options menu
	AB.MakeMenu(defaults)
	-- Register handlers for Manual and Automatic Autobanking
	if AB.savedVars.automaticTransfers then
	  em:RegisterForEvent(AB.name, EVENT_OPEN_BANK, TriggerAutobanker)
	else
	  EnableManualAutobanking()
	end
	
	em:RegisterForEvent(AB.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated )
end

--
-- EVENT
-- Register for the loading of our addon
em:RegisterForEvent(AB.name, EVENT_ADD_ON_LOADED, Initialize)