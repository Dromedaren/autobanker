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

local GetSettings = AB.GetSettings

 --
 -- Create our AddOn option menu
 --
function AB.MakeMenu()
	local defaults = AB.GetDefaultSettings()
	-- Load settings->addons menu
	local menu = AB.LAM
	
	local function GetCurrencyNameAndIcon(currencyType)
	  return zo_strformat("<<T:1>>", ZO_Currency_FormatPlatform(currencyType, nil, ZO_CURRENCY_FORMAT_PLURAL_NAME_ICON))
	end
	
	local function ClampLowestToZero(value)
	  return value < 0 and 0 or value
	end
	
	-- Create the panel for the addons menu
	local panel = {
		type = "panel",
		name = AB.addonVars.gAddonName,
		displayName = ZO_HIGHLIGHT_TEXT:Colorize(AB.addonVars.gAddonName),
		author = AB.addonVars.addonAuthor,
		version = "" .. AB.addonVars.addonVersion,
		website = AB.addonVars.website,
		slashCommand = "/autobanker",
		registerForRefresh = true,
		registerForDefaults = true,
	}

	menu:RegisterAddonPanel("Autobanker_Menu", panel)
	
  -- Make all submenues
  --
	local currencySubmenu = {}
	for currencyType, _ in ipairs(defaults.CURRENCY_DATA) do
	  local curr = GetSettings().CURRENCY_DATA[currencyType]
		if (curr.slider ~= nil) then -- TODO: Implement the other currencies, this hack allows us to have empty tables when doing ipairs
		  table.insert(currencySubmenu, {
		    type = "divider",
		    width = "full",
		    height = 5,
		    alpha = 0.5,
		  })
		  table.insert(currencySubmenu, {
		    type = "slider",
		    name = GetCurrencyNameAndIcon(currencyType),
		    min = 0,
		    max = curr.slider.max,
		    step = curr.slider.step,
		    inputLocation = "right",
			tooltip = GetString(AB_SLIDER_TOOLTIP),
		    decimals = 0,
		    getFunc = function() return curr.minimum end,
		    setFunc = function(value) curr.minimum = ClampLowestToZero(value) end,
		    default = defaults.CURRENCY_DATA[currencyType].minimum,
		    disabled = function() return not curr.deposit end,
		  })
		  table.insert(currencySubmenu, {
		    type = "checkbox",
		    name = SI_BANK_DEPOSIT,
		    getFunc = function() return curr.deposit end,
		    setFunc = function(value) curr.deposit = value end,
		    default = defaults.CURRENCY_DATA[currencyType].deposit,
		  })
		end
	end
	
	local traitSubmenu = {}
	table.insert(traitSubmenu, {
		type = "checkbox",
		name = GetString("SI_ITEMTRAITINFORMATION", ITEM_TRAIT_INFORMATION_INTRICATE), -- SI_ITEMTRAITTYPE27 (Intricate)
		getFunc = function() return GetSettings().shouldDepositIntricate end,
		setFunc = function(value) GetSettings().shouldDepositIntricate = value end,
    default = defaults.shouldDepositIntricate,
	})

  table.insert(traitSubmenu, {
    type = "checkbox",
    name = zo_strformat("<<1>> <<2>>", GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_ARMOR_INTRICATE), GetString(SI_ITEM_FORMAT_STR_ARMOR)),
    getFunc = function() return GetSettings().intricateType[ITEM_TRAIT_TYPE_ARMOR_INTRICATE] end,
    setFunc = function(value) GetSettings().intricateType[ITEM_TRAIT_TYPE_ARMOR_INTRICATE] = value end,
    disabled = function() return not GetSettings().shouldDepositIntricate end,
    default = defaults.intricateType[ITEM_TRAIT_TYPE_ARMOR_INTRICATE],
  })

  table.insert(traitSubmenu, {
    type = "checkbox",
    name = zo_strformat("<<1>> <<2>>", GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_WEAPON_INTRICATE), GetString("SI_ITEMTYPE", ITEMTYPE_WEAPON)),
    getFunc = function() return GetSettings().intricateType[ITEM_TRAIT_TYPE_WEAPON_INTRICATE] end,
    setFunc = function(value) GetSettings().intricateType[ITEM_TRAIT_TYPE_WEAPON_INTRICATE] = value end,
    disabled = function() return not GetSettings().shouldDepositIntricate end,
    default = defaults.intricateType[ITEM_TRAIT_TYPE_WEAPON_INTRICATE],
  })

  table.insert(traitSubmenu, {
    type = "checkbox",
    name = zo_strformat("<<1>> <<2>>", GetString("SI_ITEMTRAITTYPE", ITEM_TRAIT_TYPE_JEWELRY_INTRICATE), GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_JEWELRY)),
    getFunc = function() return GetSettings().intricateType[ITEM_TRAIT_TYPE_JEWELRY_INTRICATE] end,
    setFunc = function(value) GetSettings().intricateType[ITEM_TRAIT_TYPE_JEWELRY_INTRICATE] = value end,
    disabled = function() return not GetSettings().shouldDepositIntricate end,
    default = defaults.intricateType[ITEM_TRAIT_TYPE_JEWELRY_INTRICATE],
  })
    

	local researchSubmenu = {}
	table.insert(researchSubmenu, {
		type = "checkbox",
		name = GetString(SI_SMITHING_RESEARCH_RESEARCHABLE), -- Researchable
		getFunc = function() return GetSettings().shouldDepositResearchable end,
		setFunc = function(value) GetSettings().shouldDepositResearchable = value end,
    default = defaults.shouldDepositResearchable,
	})
	
	local mapsSubmenu = {
		{
			type = "checkbox",
			name = GetString("SI_SPECIALIZEDITEMTYPE", SPECIALIZED_ITEMTYPE_TROPHY_TREASURE_MAP),
			getFunc = function() return GetSettings().shouldDepositTreasureMap end,
			setFunc = function(value) GetSettings().shouldDepositTreasureMap = value end,
      default = defaults.shouldDepositTreasureMap,
		},
		{
			type = "checkbox",
			name = GetString("SI_SPECIALIZEDITEMTYPE", SPECIALIZED_ITEMTYPE_TROPHY_SURVEY_REPORT),
			getFunc = function() return GetSettings().shouldDepositSurveyReport end,
			setFunc = function(value) GetSettings().shouldDepositSurveyReport = value	end,
      default = defaults.shouldDepositSurveyReport,
		},
	}
	
	local masterWritSubmenu = {}
	table.insert(masterWritSubmenu, {
		type = "checkbox",
		name = GetString("SI_SPECIALIZEDITEMTYPE", SPECIALIZED_ITEMTYPE_MASTER_WRIT),
		getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_MASTER_WRIT] end,
		setFunc = function(value) GetSettings().typesToDeposit[ITEMTYPE_MASTER_WRIT] = value end,
    default = defaults.typesToDeposit[ITEMTYPE_MASTER_WRIT],
	})
	
	
	local craftingMaterialSubmenu = {
	  {
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_POTION_BASE),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_POTION_BASE] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_POTION_BASE] = value end,
			default = defaults.typesToDeposit[ITEMTYPE_POTION_BASE],
	  },
	  {
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_POISON_BASE),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_POISON_BASE] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_POISON_BASE] = value end,
			default = defaults.typesToDeposit[ITEMTYPE_POISON_BASE],
	  },
	  {
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_INGREDIENT),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_INGREDIENT] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_INGREDIENT] = value	end,
			default = defaults.typesToDeposit[ITEMTYPE_INGREDIENT],
		},
		{
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_REAGENT),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_REAGENT] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_REAGENT] = value end,
			default = defaults.typesToDeposit[ITEMTYPE_REAGENT],
		},
		{
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_RAW_MATERIAL),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_RAW_MATERIAL] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_RAW_MATERIAL] = value	end,
			default = defaults.typesToDeposit[ITEMTYPE_RAW_MATERIAL],
		},
	  {
	  	type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_FURNISHING_MATERIAL),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_FURNISHING_MATERIAL] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_FURNISHING_MATERIAL] = value end,
			default = defaults.typesToDeposit[ITEMTYPE_FURNISHING_MATERIAL],
	  },
	  {
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_STYLE_MATERIAL),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_STYLE_MATERIAL] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_STYLE_MATERIAL] = value	end,
			default = defaults.typesToDeposit[ITEMTYPE_STYLE_MATERIAL],
	  },
	}
	
	local consumableSubmenu = {
		{
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_DRINK),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_DRINK] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_DRINK] = value end,
			default = defaults.typesToDeposit[ITEMTYPE_DRINK],
		},
		{
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_FOOD),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_FOOD] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_FOOD] = value	end,
			default = defaults.typesToDeposit[ITEMTYPE_FOOD],
		},
	  {
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_SOUL_GEM),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_SOUL_GEM] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_SOUL_GEM] = value	end,
			default = defaults.typesToDeposit[ITEMTYPE_SOUL_GEM],
	  },
	  {
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_POTION),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_POTION] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_POTION] = value	end,
			default = defaults.typesToDeposit[ITEMTYPE_POTION],
	  },
	  {
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_POISON),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_POISON] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_POISON] = value	end,
			default = defaults.typesToDeposit[ITEMTYPE_POISON],
	  },
    {
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_RACIAL_STYLE_MOTIF),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_RACIAL_STYLE_MOTIF] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_RACIAL_STYLE_MOTIF] = value	end,
			default = defaults.typesToDeposit[ITEMTYPE_RACIAL_STYLE_MOTIF],
		},
		{
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_RECIPE),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_RECIPE] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_RECIPE] = value	end,
			default = defaults.typesToDeposit[ITEMTYPE_RECIPE],
	  },
	}
	
	local miscSubmenu = {
	  {
			type = "checkbox",
			name = GetString("SI_ITEMTYPE", ITEMTYPE_TREASURE),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_TREASURE] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_TREASURE] = value	end,
			default = defaults.typesToDeposit[ITEMTYPE_TREASURE],
	  },
	  {
			type = "checkbox",
			name = GetString(AB_TOOLS_NAME),
			getFunc = function() return GetSettings().typesToDeposit[ITEMTYPE_TOOL] end,
			setFunc = function(value)	GetSettings().typesToDeposit[ITEMTYPE_TOOL] = value	end,
			default = defaults.typesToDeposit[ITEMTYPE_TOOL],
	  },
	}
	
	-- Autobanker entries & submenus in the addon settings panel
	local options = {
		-- General Settings
		{
			type = "header",
			name = zo_strformat("<<1>> <<2>>", GetString(SI_KEYBINDINGS_CATEGORY_GENERAL), GetString(SI_GAME_MENU_SETTINGS)),
		},
		{
			type = "checkbox",
			name = GetString(AB_MANUAL_OVERRIDE),
			getFunc = function() return GetSettings().automaticTransfers end,
			setFunc = function(value)	
				GetSettings().automaticTransfers = value
				AB.events.ToggleManualBanking()
			end,
			tooltip = GetString(AB_MANUAL_OVERRIDE_TOOLTIP),
			default = defaults.automaticTransfers,
	  },
	  {
			type = "submenu",
			name = GetString(SI_INVENTORY_MODE_CURRENCY),
			controls = currencySubmenu,
	  },
	  -- Autobanker Banking settings
	  {
    	-- Trait Items
			type = "submenu",
			name = GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_TRAIT_ITEMS),
			controls = traitSubmenu,
	  },
	  {
    	-- Research
			type = "submenu",
			name = GetString("SI_ITEMTRAITINFORMATION", ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED), --  SI_ITEMTRAITINFORMATION3 (Can be researched)
			controls = researchSubmenu,
	  },
	  {
      -- Maps
			type = "submenu",
			name = GetString(AB_MAPS),
			controls = mapsSubmenu,
	  },
	  {
      -- Writs
			type = "submenu",
			name = GetString(SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES212),
			controls = masterWritSubmenu,
	  },
	  {
      -- Materials
			type = "submenu",
			name = GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_CRAFTING),
			controls = craftingMaterialSubmenu,
	  },
	  {
      -- Consumable
			type = "submenu",
			name = GetString("SI_ITEMFILTERTYPE", ITEMFILTERTYPE_CONSUMABLE),
			controls = consumableSubmenu,
	  },
	  {
      -- Miscellaneous
			type = "submenu",
			name = GetString(SI_PLAYER_MENU_MISC),
			controls = miscSubmenu,
	  },
	  {
      -- Notifications
			type = "header",
			name = GetString(SI_MAIN_MENU_NOTIFICATIONS),
	  },
	  {
			type = "checkbox",
			name = GetString(AB_NOTIFICATION_DEPOSIT),
			getFunc = function() return GetSettings().notifications.deposit end,
			setFunc = function(value)	GetSettings().notifications.deposit = value	end,
			default = defaults.notifications.deposit,
	  },
	  {
			type = "checkbox",
			name = GetString(AB_NOTIFICATION_AMOUNT),
			getFunc = function() return GetSettings().notifications.amount end,
			setFunc = function(value)	GetSettings().notifications.amount = value end,
			default = defaults.notifications.amount,
	  },
	}
	menu:RegisterOptionControls("Autobanker_Menu", options)
end