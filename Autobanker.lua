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
local eventManager = AB.EventManager
local events = AB.events
local eventHandlers = AB.events.eventHandlers
local callbackHandlers = AB.events.callbackHandlers
local filters = AB.filters

local function FindEmptySlotInBag(targetBag)
	local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(targetBag)
	for slotIndex in ZO_IterateBagSlots(targetBag) do
		if not AB.BagCache[targetBag][slotIndex] and not bagCache[slotIndex] then
			AB.BagCache[targetBag][slotIndex] = true
			return slotIndex
		end
	end
	return nil
end 

local function MoveItem(sourceBag, sourceSlot, targetBag, targetSlot, stackCount)
	local success = false 
	local valueOrFailReason = nil

	if IsProtectedFunction("RequestMoveItem") then
		success, valueOrFailReason = CallSecureProtected("RequestMoveItem", sourceBag, sourceSlot, targetBag, targetSlot, stackCount)
		if not success then
			AB.Print.message(valueOrFailReason)
		end
	else
		success, valueOrFailReason = RequestMoveItem(sourceBag, sourceSlot, targetBag, targetSlot, stackCount)
	end

	return success, valueOrFailReason
end

function AB.TryPlaceItemInEmptySlot(sourceBag, sourceSlot, targetBag, stackCount)
	local emptySlot = FindEmptySlotInBag(targetBag)
	
	-- Special case handling ESO+ members because they actually 
  -- have access to two separate different bank bags!
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
		if MoveItem(sourceBag, sourceSlot, targetBag, emptySlot, stackCount) then 
			AB.BagCache[sourceBag][sourceSlot] = nil 
			-- After the move AB.bagCache[sourceBag][sourceSlot] = nil i.e free slot again
			-- Needs to happen in EVENT_INVENTORY_SINGLE_SLOT_UPDATED?
			return true
		else 
			return false
		end
	end
end

local function CanDepositCurrency(currencyType, currencyLocation, minimum, amount)
  if not CanCurrencyBeStoredInLocation(currencyType, currencyLocation) or IsCurrencyCapped(currencyType, currencyLocation) then
		return false, GetString(AB_BANK_DEPOSIT_NOT_ALLOWED) -- Not allowed
  elseif amount <= 0 then
		local currencyIcon = ZO_Currency_GetPlatformFormattedCurrencyIcon(currencyType, nil, true)
		local howMuchWeHave = ZO_Currency_FormatPlatform(currencyType, GetCarriedCurrencyAmount(currencyType), ZO_CURRENCY_FORMAT_AMOUNT_NAME)
		local thresholdAt = ZO_Currency_FormatPlatform(currencyType, minimum, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
		return false, ZO_CachedStrFormat(GetString(AB_TRANSACTION_CURRENCY_MINIMUM_FORMAT), currencyIcon, thresholdAt, howMuchWeHave) -- "No player funds"
  else
    return true
  end
end

local function DepositCurrency(currencyType, currencyData)
  local amount = GetCarriedCurrencyAmount(currencyType) - currencyData.minimum
  local success, reason = CanDepositCurrency(currencyType, CURRENCY_LOCATION_BANK, minimum, amount)
  if success then
    local maxTransfer = GetMaxBankDeposit(currencyType)
    if amount > maxTransfer then amount = maxTransfer end
		DepositCurrencyIntoBank(currencyType, amount)
		-- Registered with EVENT_BANKED_CURRENCY_UPDATE that prints the data on success :)
  else		
		AB.Print.message(ZO_CachedStrFormat(reason))
  end 
end

function AB.TryDepositCurrencies()
	for currencyType, currencyData in ipairs(AB.GetSettings().CURRENCY_DATA) do
	  if currencyData.deposit then
			DepositCurrency(currencyType, currencyData)
	  end
	end
end

-- Locates all instances of a specified item ID in the specified bag
local function FindItemInBag(itemId, bagItemData)
	local found = {}
	for slot, itemData in ipairs(bagItemData) do
		if itemId == itemData.itemId then
			found[#found + 1] = {itemData.bagId, itemData.slotIndex}
		end
	end
	return found
end

local function StackBankbag(targetBankBag)
  if targetBankBag == BAG_BANK or targetBankBag == BAG_SUBSCRIBER_BANK then 
    StackBag(BAG_BANK)
    StackBag(BAG_SUBSCRIBER_BANK)
  elseif IsHouseBankBag(targetBankBag) then
    StackBag(targetBankBag)
  end
end


function eventHandlers.OnTriggerAutobanker(eventCode, targetBankBag)
  -- Register OnCurrencyDeposited
  eventManager:RegisterForEvent(AB.addonVars.gAddonName, EVENT_BANKED_CURRENCY_UPDATE, eventHandlers.OnCurrencyDeposited)

  if targetBankBag == BAG_BANK or targetBankBag == BAG_SUBSCRIBER_BANK or IsHouseBankBag(targetBankBag) then
		local transactions = 0
		local itemsDeposited = 0

		StackBag(BAG_BACKPACK)

		local backpackCache = SHARED_INVENTORY:GenerateFullSlotData(filters.RemoveUnwantedItems, BAG_BACKPACK)

		--[[ 
			TODO: Implement bag stacking of items 
		local bankbagsCache = SHARED_INVENTORY:GenerateFullSlotData(filters.KeepOnlyIncompleteStacks, BAG_BANK, BAG_SUBSCRIBER_BANK)

		local foundItemAlready = {}

		for _, bankItemData in ipairs(bankbagsCache) do
			if not foundItemAlready[bankbagsCache.itemId] then 
				local slots = FindItemInBag(bankItemData.itemId, backpackCache)
				-- stack onto bank
				foundItemsAlready[bankbagsCache.itemId] = true
			end
		end

		foundItemAlready = nil 
		]]

		-- NOTE: This most likely needs to be done ASYNC or with some kind of delay ZO_CallLater or something
		if transactions <= 98 then -- ZOS antispam Limit?
			for _, itemData in ipairs(backpackCache) do
				local itemLink = GetItemLink(BAG_BACKPACK, itemData.slotIndex)
				local itemId = GetItemInstanceId(BAG_BACKPACK, itemData.slotIndex)
				local stackSize, maxStack = GetSlotStackSize(BAG_BACKPACK, itemData.slotIndex)

				local couldPlaceItem = AB.TryPlaceItemInEmptySlot(BAG_BACKPACK, itemData.slotIndex, targetBankBag, stackSize)
				if couldPlaceItem then 
					itemsDeposited = itemsDeposited + stackSize
					transactions = transactions + 1
					AB.Print.itemDeposited(itemLink, stackSize)
				else
					-- Bank is completely FULL
					break
				end
			end
		end

		AB.Print.itemsDeposited(itemsDeposited)

		AB.TryDepositCurrencies()
  end
	-- ON_BANK_CLOSE Unregisters OnCurrencyDeposited
	StackBankbag(targetBankBag)
end

--
-- KEYBIND
--
AB.autobankerKeybindButtonGroup =
{
  alignment = KEYBIND_STRIP_ALIGN_CENTER,
  {
    name = GetString(AB_TRIGGER_AUTOBANKER),
    keybind = "UI_SHORTCUT_QUATERNARY",
    callback = function() eventHandlers.OnTriggerAutobanker(EVENT_OPEN_BANK, GetBankingBag()) end,
  },
}

--
-- AddOn Initialization
--
local function OnPlayerActivated()
  eventManager:UnregisterForEvent(AB.addonVars.gAddonName, EVENT_PLAYER_ACTIVATED)
  -- Initialization message
  AB.Print.message(zo_strformat("<<1>> <<2>>", GetString(AB_NAME_DISPLAY), GetString(AB_INIT)))
  AB.addonVars.gPlayerActivated = true
end

local function Initialize(event, addonName)
	-- filter for just Autobanker's addon event  
	if addonName ~= AB.addonVars.gAddonName then return end
	eventManager:UnregisterForEvent(AB.addonVars.gAddonName, EVENT_ADD_ON_LOADED)

	if AB.libsProperlyLoaded then
		-- Load saved variables
	  AB.LoadSavedVariables()
	  AB.addonVars.gSettingsLoaded = true

	  -- Make our options menu
	  AB.MakeMenu()
	
	  -- Depending on the saved settings, enable or disable automatic transfers
	  events.ToggleManualBanking()
	  eventManager:RegisterForEvent(AB.addonVars.gAddonName, EVENT_CLOSE_BANK, eventHandlers.OnCloseBank)

	  AB.addonVars.gAddonLoaded = true
	  eventManager:RegisterForEvent(AB.addonVars.gAddonName, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
	else
		AB.Print.message(zo_strformat(GetString(AB_ADDON_FAILURE), AB.addonVars.gAddonName)) return
	end
end

eventManager:RegisterForEvent(AB.addonVars.gAddonName, EVENT_ADD_ON_LOADED, Initialize)
