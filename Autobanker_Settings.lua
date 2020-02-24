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

-- Saved Variables and default settings
AB.settingsVars = {}
AB.settingsVars.settings = {}
AB.settingsVars.defaultSettings = {}
AB.svDefaultName = "Default"

-- Default values for saved vars
local defaults = {
  worldname = GetWorldName(),
	characterId = GetCurrentCharacterId(),
	-- Notifications
	notifications = {
		deposit = true,
		amount = true,
	},
  typesToDeposit = {
		[ITEMTYPE_DRINK] = false,
		[ITEMTYPE_FOOD] = false,
		[ITEMTYPE_FURNISHING_MATERIAL] = false,
		[ITEMTYPE_INGREDIENT] = false,
		[ITEMTYPE_MASTER_WRIT] = false,
		[ITEMTYPE_POISON] = false,
		[ITEMTYPE_POISON_BASE] = false,
		[ITEMTYPE_POTION] = false,
		[ITEMTYPE_POTION_BASE] = false,
		[ITEMTYPE_RAW_MATERIAL] = false, -- new
		[ITEMTYPE_REAGENT] = false, -- new
		[ITEMTYPE_RECIPE] = false,
		[ITEMTYPE_RACIAL_STYLE_MOTIF] = false, -- new
		[ITEMTYPE_SOUL_GEM] = false,
		[ITEMTYPE_STYLE_MATERIAL] = false,
		[ITEMTYPE_TOOL] = false,
		[ITEMTYPE_TREASURE] = false,
  },
  -- Specific categories
  intricateType = {
    [ITEM_TRAIT_TYPE_ARMOR_INTRICATE] = false,
    [ITEM_TRAIT_TYPE_WEAPON_INTRICATE] = false,
    [ITEM_TRAIT_TYPE_JEWELRY_INTRICATE] = false,
	},
  -- Manual or Automatic deposits
  automaticTransfers = false,
  useGlobalSettings = false,
	-- Toggles depositing all intricate types
	shouldDepositIntricate = false,
  shouldDepositTreasureMap = false,
  shouldDepositSurveyReport = false,
  shouldDepositResearchable = false,

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

AB.settingsVars.defaultSettings = defaults

function AB.GetDefaultSettings()
    return AB.settingsVars.defaultSettings
end

function AB.GetDefaultSetting(key)
	return AB.settingsVars.defaultSettings[key]
end

function AB.GetSettings()
    if not AB.addonVars.gSettingsLoaded then return end 
    return AB.settingsVars.settings
end

function AB.GetSetting(key)
	if not AB.addonVars.gSettingsLoaded then return end
	return AB.settingsVars.settings[key]
end

function AB.LoadSavedVariables()
	AB.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(AB.addonVars.savedVarName, AB.addonVars.savedVarVersion, nil, AB.GetDefaultSettings())
end

-- ADDON CHAT OUTPUT
--
function AB.Print.message(message)
	CHAT_SYSTEM:AddMessage(message)
end
  
function AB.Print.itemDeposited(itemLink, stackCount)
  if AB.GetSettings().notifications.deposit then
    AB.Print.message(zo_strformat(GetString(AB_TRANSACTION_FORMAT), itemLink), stackCount)
  end
end
  
function AB.Print.itemsDeposited(itemsDeposited)
  if AB.GetSettings().notifications.amount then
    AB.Print.message(zo_strformat(GetString(AB_COUNT_FORMAT), itemsDeposited))
  end
end
  