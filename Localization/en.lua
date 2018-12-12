 local strings = {

	-- General strings in AB (Autobanker)
	AB_INIT = "Autobanker Initialized...",
	AB_TRIGGER_AUTOBANKER = "Run Autobanker",
	AB_MANUAL_OVERRIDE = "Automatic Autobanker transfers",
	AB_MANUAL_OVERRIDE_TOOLTIP = "This option allows you to manually activate Autobanker with a button press on the bottom of the banking interaction scene instead of having Autobanker automatically depositing for you.",
	
	-- Autobanker Menu - Deposit filters
	AB_RESEARCHABLE = "Researchable items",
	AB_TOOLS_NAME = "Lockpicks And Alliance vs Alliance Tools",
		
	AB_MAPS = "Maps",	
		
	-- Notifications
	AB_NOTIFICATION_DEPOSIT = "Display (in chat) the items deposited.",
	AB_NOTIFICATION_AMOUNT = "Display (in chat) the number of items deposited.",
  
	-- String formatting
	AB_TRANSACTION_FORMAT = "Autobanker Transfered <<2>>x <<t:1>>.",
	AB_COUNT_FORMAT = "Autobanker Transfered <<1>> <<1[item/items]>>",
	AB_SLIDER_TOOLTIP = "Autobanker will deposit everything above the slider threshold",
	AB_CURT_TRANSFER_FORMAT = "Autobanker Deposited",
	
	AB_PROFILES_DROPDOWN_NAME = "Select a character to edit",
}

for stringId, stringValue in pairs(strings) do
   ZO_CreateStringId(stringId, stringValue)
   SafeAddVersion(stringId, 1)
end