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

-- Global Event Manager
AB.EventManager = GetEventManager()
AB.CallbackManager = CALLBACK_MANAGER
AB.privateCallbackManager = ZO_CallbackObject:New()

-- Events table
AB.events = {}

-- Handlers
AB.events.eventHandlers = {}
AB.events.callbackHandlers = {}

local events = AB.events
local eventHandlers = AB.events.eventHandlers
local callbackHandlers = AB.events.callbackHandlers

-- Fragments
AB.Fragments = {}
AB.Fragments.BANK_FRAGMENT = BANK_FRAGMENT
AB.Fragments.BACKPACK_BANK_LAYOUT_FRAGMENT = BACKPACK_BANK_LAYOUT_FRAGMENT

-- EVENT_BANKED_CURRENCY_UPDATE
-- EVENT_CARRIED_CURRENCY_UPDATE
-- EVENT_BANK_IS_FULL
-- EVENT_BANK_DEPOSIT_NOT_ALLOWED

local function AddKeyBinds()
  KEYBIND_STRIP:AddKeybindButtonGroup(AB.autobankerKeybindButtonGroup)
end

local function RemoveKeybinds()
  KEYBIND_STRIP:RemoveKeybindButtonGroup(AB.autobankerKeybindButtonGroup)
end

function callbackHandlers.AutobankerOnStateChanged(oldState, newState)
  if newState == SCENE_SHOWING then
    AddKeyBinds()
  elseif newState == SCENE_HIDDEN then
    RemoveKeybinds()
  end
end

function events.EnableManualAutobanking()
  AB.Fragments.BANK_FRAGMENT:RegisterCallback("StateChange", callbackHandlers.AutobankerOnStateChanged)
  AB.Fragments.BACKPACK_BANK_LAYOUT_FRAGMENT:RegisterCallback("StateChange", callbackHandlers.AutobankerOnStateChanged)
  AB.Print.message(ZO_CachedStrFormat(GetString(AB_MANUAL_ENABLED)))
  -- Unregister automatic banking
  AB.EventManager:UnregisterForEvent(AB.addonVars.gAddonName, EVENT_OPEN_BANK)
  AB.addonVars.gAutobanking = false
end

function events.DisableManualAutobanking()
  AB.Fragments.BANK_FRAGMENT:UnregisterCallback("StateChange", callbackHandlers.AutobankerOnStateChanged)
  AB.Fragments.BACKPACK_BANK_LAYOUT_FRAGMENT:UnregisterCallback("StateChange", callbackHandlers.AutobankerOnStateChanged)
  AB.Print.message(ZO_CachedStrFormat(GetString(AB_MANUAL_DISABLED)))
  -- Register automatic banking 
  AB.EventManager:RegisterForEvent(AB.addonVars.gAddonName, EVENT_OPEN_BANK, eventHandlers.OnTriggerAutobanker)
  AB.addonVars.gAutobanking = true
end

function events.ToggleManualBanking()
  if AB.GetSettings().automaticTransfers then
    events.DisableManualAutobanking()
  else
    events.EnableManualAutobanking()
  end
end

function eventHandlers.OnCloseBank(eventCode)
  -- Unregister OnCurrencyDeposited
  AB.EventManager:UnregisterForEvent(AB.addonVars.gAddonName, EVENT_BANKED_CURRENCY_UPDATE)
end

function eventHandlers.OnCurrencyDeposited(eventCode, currencyType, newValue, oldValue)
  -- How much is Deposited
  local amount = zo_abs(newValue - oldValue)
  AB.Print.message(ZO_CachedStrFormat(GetString(AB_TRANSACTION_CURRENCY_FORMAT), ZO_Currency_FormatPlatform(currencyType, amount, ZO_CURRENCY_FORMAT_AMOUNT_ICON)))
end
