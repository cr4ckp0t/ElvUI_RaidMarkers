-------------------------------------------------------------------------------
-- ElvUI Raid Markers Bar By Crackpotx
-- Contains modifications graciously provided by Dridzt!
-------------------------------------------------------------------------------
local E, _, V, P, G, _ = unpack(ElvUI)
local L = E.Libs.ACL:GetLocale("ElvUI_RaidMarkers", false)
local DT = E:GetModule("DataTexts")
local TargetFrame = CreateFrame("Frame", "ElvUI_RaidMarkersDatatextTargetFrame", E.UIParent, "UIDropDownMenuTemplate")
local LocationFrame = CreateFrame("Frame", "ElvUI_RaidMarkersDatatextLocationFrame", E.UIParent, "UIDropDownMenuTemplate")

-- local api cache
local IsShiftKeyDown = IsShiftKeyDown
local PlaceRaidMarker = PlaceRaidMarker
local SetRaidTarget = SetRaidTarget
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local UnitExists = UnitExists

local strjoin = strjoin

local displayString = ""
local hexColor

local markerMap = {
	[1] = {Name = L["Star"], RT = 1, WM = 5},	-- yellow/star
	[2] = {Name = L["Circle"], RT = 2, WM = 6}, -- orange/circle
	[3] = {Name = L["Diamond"], RT = 3, WM = 3},	-- purple/diamond
	[4] = {Name = L["Triangle"], RT = 4, WM = 2},	-- green/triangle
	[5] = {Name = L["Moon"], RT = 5, WM = 7}, -- white/moon
	[6] = {Name = L["Square"], RT = 6, WM = 1},	-- blue/square
	[7] = {Name = L["Red X"], RT = 7, WM = 4},	-- red/cross
	[8] = {Name = L["Skull"], RT = 8, WM = 8}, -- white/skull
	[9] = {Name = L["Remove Marker"], RT = 0, WM = 0},	-- clear target/flare
}

local function TargetClick()
	SetRaidTarget(UnitExists("target") and "target" or "player")
end

local function CreateTargetMenu()
	for i = 9, 1, -1 do
		UIDropDownMenu_AddButton({
			text = markerMap[i].Name,
			icon = i == 9 and "Interface\\BUTTONS\\UI-GroupLoot-Pass-Up" or ("Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"):format(i),
			func = TargetClick,
			arg1 = markerMap[i].RT,
			hasArrow = false,
			notCheckable = true,
		}, 1)
	end
end

local function LocationClick(_, id)
	PlaceRaidMarker(id)
end

local function CreateLocationMenu()
	for i = 9, 1, -1 do
		UIDropDownMenu_AddButton({
			text = markerMap[i].Name,
			icon = i == 9 and "Interface\\BUTTONS\\UI-GroupLoot-Pass-Up" or ("Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"):format(i),
			func = LocationClick,
			arg1 = markerMap[i].WM,
			hasArrow = false,
			notCheckable = true,
		}, 1)
	end
end

local function OnEvent(self, ...)
	self.text:SetText(displayString:format(L["Raid Markers"]))
end

local function OnEnter(self)
	DT:SetupTooltip(self)
	DT.tooltip:AddLine(("%s%s|r |cffffffff%s|r"):format(hexColor, L["ElvUI"], L["Raid Markers"]))
	DT.tooltip:AddLine(" ")
	DT.tooltip:AddDoubleLine(L["Left Click"], L["Open Target Marker List"], 1, 1, 0, 1, 1, 1)
	--DT.tooltip:AddDoubleLine(L["Right Click"], L["Open Location Marker List"], 1, 1, 0, 1, 1, 1)
	DT.tooltip:AddDoubleLine(L["Shift + Left Click"], L["Clear Target Marker"], 1, 1, 0, 1, 1, 1)
	--DT.tooltip:AddDoubleLine(L["Shift + Right Click"], L["Clear All Location Markers"], 1, 1, 0, 1, 1, 1)
	DT.tooltip:Show()
end

local function OnClick(self, button)
	DT.tooltip:Hide()

	if button == "LeftButton" then
		if IsShiftKeyDown() then
			TargetClick(button, 0)
		else
			-- show the target menu
			CreateTargetMenu()
			ToggleDropDownMenu(1, nil, TargetFrame, self, 0, 0)
		end
	elseif button == "RightButton" then
		if IsShiftKeyDown() then
			LocationClick(button, 0)
		else
			-- show the location marker menu
			--CreateLocationMenu()
			--ToggleDropDownMenu(1, nil, LocationFrame, self, 0, 0)
		end
	end
end

local function ValueColorUpdate(self, hex)
	displayString = strjoin('', hex, '%s|r')
	hexColor = hex
	OnEvent(self)
end

TargetFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
TargetFrame:SetScript("OnEvent", function(self)
	self.initialize = CreateTargetMenu
	self.displayMode = "MENU"
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)

LocationFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
LocationFrame:SetScript("OnEvent", function(self)
	self.initialize = CreateLocationMenu
	self.displayMode = "MENU"
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)

DT:RegisterDatatext("Raid Markers", nil, {"PLAYER_ENTERING_WORLD"}, OnEvent, nil, OnClick, OnEnter, nil, L["Raid Markers"], nil, ValueColorUpdate)
