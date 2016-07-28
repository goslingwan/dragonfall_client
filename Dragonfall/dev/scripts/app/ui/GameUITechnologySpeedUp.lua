--
-- Author: Danny He
-- Date: 2015-01-19 14:18:33
--
local WidgetSpeedUp = import("..widget.WidgetSpeedUp")
local GameUITechnologySpeedUp = class("GameUITechnologySpeedUp",WidgetSpeedUp)
local GameUtils = GameUtils

function GameUITechnologySpeedUp:ctor()
    GameUITechnologySpeedUp.super.ctor(self)
    if User:HasProductionTechEvent() then
        self.technologyEvent = User.productionTechEvents[1]
    end
    if not self.technologyEvent then
        self:LeftButtonClicked()
    else
        local event = self.technologyEvent
        local time, percent = UtilsForEvent:GetEventInfo(event)
        self:SetAccBtnsGroup("productionTechEvents",event)
        self:SetUpgradeTip(string.format(_("正在研发%s到 Level %d"), UtilsForTech:GetTechLocalize(event.name), User.productionTechs[event.name].level + 1))
        self:SetProgressInfo(time, percent)
        self:CheckCanSpeedUpFree()
        self:OnFreeButtonClicked(handler(self, self.FreeSpeedUpAction))
        User:AddListenOnType(self, "productionTechEvents")
        scheduleAt(self, function()
            if self.progress and User:HasProductionTechEvent() then
                local event = User.productionTechEvents[1]
                local time, percent = UtilsForEvent:GetEventInfo(event)
                self:SetProgressInfo(time, percent)
                if self.CheckCanSpeedUpFree then
                    self:CheckCanSpeedUpFree()
                end
            end
        end)
    end
end

function GameUITechnologySpeedUp:FreeSpeedUpAction()
    local time, percent = UtilsForEvent:GetEventInfo(self:GetEvent())
    if time > 2 then
        NetManager:getFreeSpeedUpPromise("productionTechEvents", self:GetEvent().id)
    end
end

function GameUITechnologySpeedUp:onCleanup()
    User:RemoveListenerOnType(self, "productionTechEvents")
    GameUITechnologySpeedUp.super.onCleanup(self)
end

function GameUITechnologySpeedUp:OnUserDataChanged_productionTechEvents(userData, deltaData)
    local ok, value = deltaData("productionTechEvents.edit")
    if ok then
        self.technologyEvent = value[1]
    end
    local upgrading_event = User.productionTechEvents[1]
    if not upgrading_event or not self:GetEvent() or upgrading_event.id ~= self:GetEvent().id then
        self:LeftButtonClicked()
        return
    end
        self:CheckCanSpeedUpFree()
end

function GameUITechnologySpeedUp:GetEvent()
    return self.technologyEvent
end

function GameUITechnologySpeedUp:CheckCanSpeedUpFree()
    local time = UtilsForEvent:GetEventInfo(self:GetEvent())
    self:SetFreeButtonEnabled(time <= DataUtils:getFreeSpeedUpLimitTime())
end

return GameUITechnologySpeedUp

