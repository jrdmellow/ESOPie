-------------------------------------------------------------------------------
-- Pie Menu Controller

local ESOPie_MenuController = ZO_InteractiveRadialMenuController:Subclass()

function ESOPie_MenuController:New(...)
    return ZO_InteractiveRadialMenuController.New(self, ...)
end

function ESOPie_MenuController:Initialize(control, entryTemplate, animationTemplate, entryAnimationTemplate)
    ZO_InteractiveRadialMenuController.Initialize(self, control, entryTemplate, animationTemplate, entryAnimationTemplate)
    self.menu.presetLabel = self.menuControl:GetNamedChild("PresetName")
    self.menu.trackQuickslot = self.menuControl:GetNamedChild("TrackQuickslot")
    self.menu.trackGamepad = self.menuControl:GetNamedChild("TrackGamepad")
end

function ESOPie_MenuController:PrepareForInteraction()
    if not SCENE_MANAGER:IsShowing("hud") then
        return false
    end
    return true
end

function ESOPie_MenuController:SetupEntryControl(control, data)
    if not data then return end
    if data.selected then
        if control.glow then
            control.glow:SetAlpha(1)
        end
        control.animation:GetLastAnimation():SetAnimatedControl(nil)
    else
        if control.glow then
            control.glow:SetAlpha(0)
        end
        control.animation:GetLastAnimation():SetAnimatedControl(control.glow)
    end
end

function ESOPie_MenuController:OnSelectionChangedCallback(selectedEntry)
    if not selectedEntry then return end
    if selectedEntry.name then
        self.menuControl.selectedLabel:SetText(selectedEntry.name)
    else
        self.menuControl.selectedLabel:SetText("")
    end
    ESOPie:SetSelectedSlotFromEntry(selectedEntry)
end

function ESOPie_MenuController:PopulateMenu()
    local ring = ESOPie.displayedRing
    if not ring or not ring.slots then Notify("Displayed ring not valid.") return end

    local maxSlots = ESOPie.maxVisibleSlots
    if ESOPie.showCancelButton then
        maxSlots = maxSlots - 1
    end
    for i=1, math.min(maxSlots, #ring.slots) do
        local slotInfo = ring.slots[i]
        Print(LOG_VERBOSE, "   " .. i .. " " .. slotInfo.name)
        local name = slotInfo.name
        local icon = slotInfo.icon
        if name == nil or name == '' then name = "Slot " .. i end
        if icon == nil or icon == '' then icon = ESOPIE_ICON_SLOT_DEFUALT end
        self.menu:AddEntry(name, icon, icon, function() ESOPie:ExecuteCallback(slotInfo) end, slotInfo)
    end
    if ESOPie.showCancelButton then
        self.menu:AddEntry(L(SI_RADIAL_MENU_CANCEL_BUTTON), ESOPIE_ICON_SLOT_CANCEL, ESOPIE_ICON_SLOT_CANCEL, nil, nil)
    end
end

-------------------------------------------------------------------------------
-- Templates

function ESOPieUI_PieMenuInitialize(self)
    self.selectedLabel = self:GetNamedChild("SelectedLabel")
    if IsInGamepadPreferredMode() then
        self.selectedLabel:SetFont("ZoFontGamepad54")
    else
        self.selectedLabel:SetFont("ZoInteractionPrompt")
    end
    self.selectedLabel:SetText("")
end

function ESOPieUI_EntryTemplateInitialize(self)
    self.glow = self:GetNamedChild("Glow")
    self.icon = self:GetNamedChild("Icon")
    self.count = self:GetNamedChild("CountText")
    self.cooldown = self:GetNamedChild("Cooldown")
    self.frame = self:GetNamedChild("Frame")
    self.status = self:GetNamedChild("StatusText")
    ZO_SelectableItemRadialMenuEntryTemplate_OnInitialized(self)
end
