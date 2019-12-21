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

 local strings = {

	-- General strings in AB (Autobanker)
	AB_NAME = "Autobanker",
	AB_NAME_SHORT = "AB",
	AB_NAME_DISPLAY = "|cEFFBBEAutobanker|r",
	AB_NAME_AUTHOR_DISPLAY = "|cEFFBBEr4cken|r",
	AB_NAME_AUTHOR = "@r4cken",
	AB_INIT = "Initialized...",
	AB_TRIGGER_AUTOBANKER = "Run " .. AB_NAME,

	-- Menu
	AB_MANUAL_OVERRIDE = "Automatic " .. AB_NAME .. " transfers",
	AB_MANUAL_OVERRIDE_TOOLTIP = "This option allows you to manually activate " .. AB_NAME .. " with a button press on the bottom of the banking interaction scene instead of having Autobanker automatically depositing for you.",
	AB_SLIDER_TOOLTIP = AB_NAME.. " will deposit everything above the slider threshold",

	-- Menu - Deposit filters
	AB_RESEARCHABLE = "Researchable items",
	AB_TOOLS_NAME = "Lockpicks And Alliance vs Alliance Tools",
	AB_MAPS = "Maps",	
		
	-- Notifications
	AB_NOTIFICATION_DEPOSIT = "Display (in chat) the items deposited.",
	AB_NOTIFICATION_AMOUNT = "Display (in chat) the number of items deposited.",
  
	-- String formatting
	AB_TRANSACTION_FORMAT = AB_NAME .. " Transfered <<2>>x <<t:1>>.",
	AB_TRANSACTION_AMOUNT_FORMAT = AB_NAME .. " Transfered <<1>> <<1[item/items]>>",
	AB_TRANSACTION_CURRENCY_FORMAT = AB_NAME .. " Deposited <<1>>",
	AB_TRANSACTION_CURRENCY_MINIMUM_FORMAT = "Minimum deposit threshhold for <<1>> is <<2>>, you have <<3>>",

	-- Errors
	AB_LIBRARY_MISSING = "Error: Required library <<1>> not found. Addon will not work.",
	AB_ADDON_FAILURE = "Error: Dependencies not loaded successfully, <<1>> will not load.",
  AB_BANK_DEPOSIT_NOT_ALLOWED = GetString(SI_INVENTORY_ERROR_BANK_DEPOSIT_NOT_ALLOWED),
	AB_NO_PLAYER_FUNDS = GetString(SI_GAMEPAD_INVENTORY_ERROR_NO_PLAYER_FUNDS),
}

for stringId, stringValue in pairs(strings) do
   ZO_CreateStringId(stringId, stringValue)
   SafeAddVersion(stringId, 1)
end