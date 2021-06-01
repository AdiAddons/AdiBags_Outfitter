--[[
AdiBags_Outfitter - Adds Outfitter set filters to AdiBags.
Copyright 2010-2021 Adirelle (adirelle@gmail.com)
All rights reserved.
--]]

local _, ns = ...

local addon = LibStub('AceAddon-3.0'):GetAddon('AdiBags')
local L = setmetatable({}, {__index = addon.L})

do -- Localization
	--@localization(locale="enUS", format="lua_additive_table", handle-unlocalized="english")@
	local locale = GetLocale()
	if locale == "frFR" then
		--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized="ignore")@
	elseif locale == "deDE" then
		--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized="ignore")@
	elseif locale == "esMX" then
		--@localization(locale="esMX", format="lua_additive_table", handle-unlocalized="ignore")@
	elseif locale == "ruRU" then
		--@localization(locale="ruRU", format="lua_additive_table", handle-unlocalized="ignore")@
	elseif locale == "esES" then
		--@localization(locale="esES", format="lua_additive_table", handle-unlocalized="ignore")@
	elseif locale == "zhTW" then
		--@localization(locale="zhTW", format="lua_additive_table", handle-unlocalized="ignore")@
	elseif locale == "zhCN" then
		--@localization(locale="zhCN", format="lua_additive_table", handle-unlocalized="ignore")@
	elseif locale == "koKR" then
		--@localization(locale="koKR", format="lua_additive_table", handle-unlocalized="ignore")@
	end
end

-- The filter itself

-- Use a priority slightly higher than the Gear Manager filter one
local setFilter = addon:RegisterFilter("OutfitterSets", 92, 'ABEvent-1.0')
setFilter.uiName = L['Outfitter item sets']
setFilter.uiDesc = L['Put items belonging to one or more sets of Outfitter in specific sections.']

function setFilter:OnInitialize()
	self.db = addon.db:RegisterNamespace('OutfitterSets', {
		profile = { oneSectionPerSet = true },
		char = { mergedSets = { ['*'] = false } },
	})
end

local function UpdateSets(...)
	setFilter:UpdateSets(...)
	setFilter:SendMessage('AdiBags_FiltersChanged')
end

function setFilter:OnEnable()
	Outfitter:RegisterOutfitEvent("EDIT_OUTFIT", UpdateSets)
	Outfitter:RegisterOutfitEvent("ADD_OUTFIT", UpdateSets)
	Outfitter:RegisterOutfitEvent("DELETE_OUTFIT", UpdateSets)
	if Outfitter:IsInitialized() then
		self:UpdateSets()
	else
		Outfitter:RegisterOutfitEvent("OUTFITTER_INIT", UpdateSets)
	end
	addon:UpdateFilters()
end

function setFilter:OnDisable()
	Outfitter:UnregisterOutfitEvent("OUTFITTER_INIT", UpdateSets)
	Outfitter:UnregisterOutfitEvent("EDIT_OUTFIT", UpdateSets)
	Outfitter:UnregisterOutfitEvent("ADD_OUTFIT", UpdateSets)
	Outfitter:UnregisterOutfitEvent("DELETE_OUTFIT", UpdateSets)
	addon:UpdateFilters()
end

local setNames = {}

function setFilter:UpdateSets()
	if not Outfitter:IsInitialized() then return end
	wipe(setNames)
	for i, category in pairs(Outfitter:GetCategoryOrder()) do
		for j, outfit in pairs(Outfitter:GetOutfitsByCategoryID(category)) do
			if not outfit:IsEmpty() then
				local name = outfit:GetName()
				setNames[name] = name
			end
		end
	end
end

function setFilter:Filter(slotData)
	if not Outfitter:IsInitialized() or (slotData.link and strmatch(slotData.link, "battlepet:")) then
		return
	end
	local itemInfo = Outfitter:GetItemInfoFromLink(slotData.link)
	for name in pairs(setNames) do
		local outfit = Outfitter:FindOutfitByName(name)
		if outfit and outfit:OutfitUsesItem(itemInfo) then
			if not self.db.profile.oneSectionPerSet or self.db.char.mergedSets[name] then
				return L['Sets'], L["Equipment"]
			else
				return L["Set: %s"]:format(name), L["Equipment"]
			end
		end
	end
end

function setFilter:GetFilterOptions()
	return {
		oneSectionPerSet = {
			name = L['One section per set'],
			desc = L['Check this to display one individual section per set. If this is disabled, there will be one big "Sets" section.'],
			type = 'toggle',
			order = 10,
		},
		mergedSets = {
			name = L['Merged sets'],
			desc = L['Check sets that should be merged into a unique "Sets" section. This is obviously a per-character setting.'],
			type = 'multiselect',
			order = 20,
			values = setNames,
			get = function(info, name)
				return self.db.char.mergedSets[name]
			end,
			set = function(info, name, value)
				self.db.char.mergedSets[name] = value
				self:SendMessage('AdiBags_FiltersChanged')
			end,
			disabled = function() return not self.db.profile.oneSectionPerSet end,
		},
	}, addon:GetOptionHandler(self, true)
end
