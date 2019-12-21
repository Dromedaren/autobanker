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

-- Addon variables
AB.addonVars = {}
local addonVars = AB.addonVars

addonVars.addonVersion 				= GetString(AB_VERSION)
addonVars.addonVersionNumber		= 1.7
addonVars.gAddonName 				= GetString(AB_NAME)
addonVars.gAddonNameShort 			= GetString(AB_NAME_SHORT)
addonVars.addonNameDisplay 			= GetString(AB_NAME_DISPLAY)
addonVars.addonAuthor 				= GetString(AB_NAME_AUTHOR_DISPLAY)
addonVars.addonAuthorDisplayNameEU  = GetString(AB_NAME_AUTHOR)
addonVars.website 					= GetString(AB_WEBSITE)
addonVars.gAddonLoaded 				= false
addonVars.gPlayerActivated 			= false
addonVars.gSettingsLoaded 			= false
addonVars.gAutobanking              = false

--SavedVariables constants
addonVars.savedVarName				= addonVars.gAddonName .. "SavedVars"
addonVars.savedGlobalVarName        = addonVars.gAddonName .. "GlobalSavedVars"
addonVars.savedVarVersion			= 5
AB.APIVersion = GetAPIVersion()
AB.APIVersionLength = string.len(AB.APIVersion) or 6

-- Make a bag cache to to find empty slots
AB.BagCache = {
    [BAG_BANK] = {},
    [BAG_BACKPACK] = {},
	[BAG_SUBSCRIBER_BANK] = {},
	[BAG_HOUSE_BANK_ONE] = {},
	[BAG_HOUSE_BANK_TWO] = {},
	[BAG_HOUSE_BANK_THREE] = {},
	[BAG_HOUSE_BANK_FOUR] = {},
	[BAG_HOUSE_BANK_FIVE] = {},
	[BAG_HOUSE_BANK_SIX] = {},
	[BAG_HOUSE_BANK_SEVEN] = {},
	[BAG_HOUSE_BANK_EIGHT] = {},
	[BAG_HOUSE_BANK_NINE] = {},
	[BAG_HOUSE_BANK_TEN] = {}
}

AB.QtyBagCache = {}
AB.IncompleteBagStacks = {}

--The bagId to player inventory type mapping
AB.bagMapping = {}
local bagMapping = AB.bagMapping
bagMapping.bagToPlayerInv = {
    [BAG_BACKPACK]          = INVENTORY_BACKPACK,
    [BAG_SUBSCRIBER_BANK]   = INVENTORY_BANK,
    [BAG_BANK]              = INVENTORY_BANK,
    [BAG_HOUSE_BANK_ONE]    = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_TWO]    = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_THREE]  = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_FOUR]   = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_FIVE]   = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_SIX]    = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_SEVEN]  = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_EIGHT]  = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_NINE]   = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_TEN]    = INVENTORY_HOUSE_BANK,
    [BAG_GUILDBANK]         = INVENTORY_GUILD_BANK,
    [BAG_VIRTUAL]           = INVENTORY_CRAFT_BAG,   
}

bagMapping.bagToBagName = {
    [BAG_BACKPACK]          = "Backpack",
    [BAG_SUBSCRIBER_BANK]   = "Subscriber bank",
    [BAG_BANK]              = "Bank",
    [BAG_HOUSE_BANK_ONE]    = "House bank one",
    [BAG_HOUSE_BANK_TWO]    = "House bank two",
    [BAG_HOUSE_BANK_THREE]  = "House bank three",
    [BAG_HOUSE_BANK_FOUR]   = "House bank four",
    [BAG_HOUSE_BANK_FIVE]   = "House bank five",
    [BAG_HOUSE_BANK_SIX]    = "House bank six",
    [BAG_HOUSE_BANK_SEVEN]  = "House bank seven",
    [BAG_HOUSE_BANK_EIGHT]  = "House bank eight",
    [BAG_HOUSE_BANK_NINE]   = "House bank nine",
    [BAG_HOUSE_BANK_TEN]    = "House bank ten",
    [BAG_GUILDBANK]         = "Guildbank",
    [BAG_VIRTUAL]           = "Craft",
}

--Control vars
AB.ZOControlVars = {}
AB.ZOControlVars.INV                            = ZO_PlayerInventory
AB.ZOControlVars.INV_NAME                       = AB.ZOControlVars.INV:GetName()
AB.ZOControlVars.BAG_BACKPACK                   = ZO_PlayerInventoryBackpack
AB.ZOControlVars.BACKPACK_BAG                   = ZO_PlayerInventoryListContents
AB.ZOControlVars.CRAFTBAG                       = ZO_CraftBag
AB.ZOControlVars.CRAFTBAG_NAME                  = AB.ZOControlVars.CRAFTBAG:GetName()
AB.ZOControlVars.CRAFTBAG_BAG                   = ZO_CraftBagListContents
AB.ZOControlVars.BANK_INV                       = ZO_PlayerBank
AB.ZOControlVars.BANK_INV_NAME                  = AB.ZOControlVars.BANK_INV:GetName()
AB.ZOControlVars.BANK                           = ZO_PlayerBankBackpack
AB.ZOControlVars.BANK_BAG		                = ZO_PlayerBankBackpackContents
AB.ZOControlVars.BANK_MENUBAR_BUTTON_WITHDRAW	= ZO_PlayerBankMenuBarButton1
AB.ZOControlVars.BANK_MENUBAR_BUTTON_DEPOSIT    = ZO_PlayerBankMenuBarButton2
AB.ZOControlVars.bankSceneName				    = "bank"

--
-- LOAD LIBRARIES
AB.libsProperlyLoaded = false

local function loadLibrary(library, libraryName)
    local library = library
    if library == nil and LibStub then library = LibStub:GetLibrary(libraryName, true) end
    if library == nil then
      d(zo_strformat(GetString(AB_LIBRARY_MISSING), libraryName)) 
      return nil
    else
        return library
    end
end

local LAM = loadLibrary(LibAddonMenu2, "LibAddonMenu-2.0")
local LR =  loadLibrary(LibResearch, "LibResearch")
if LAM ~= nil and LR ~= nil then AB.LAM = LAM AB.LR = LR else return end

-- ON LIBRARY LOAD FAILURES WE NEVER GET HERE.. --
------------------------------------------------------
-- All loaded properly
AB.libsProperlyLoaded = true
-- END LOAD LIBRARIES
--
