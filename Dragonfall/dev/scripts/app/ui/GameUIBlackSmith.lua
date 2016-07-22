--
-- Author: gaozhou
-- Date: 2014-08-18 14:33:28
--
local window = import("..utils.window")
local GameUIEquip = import(".GameUIEquip")
local GameUIBlackSmith = UIKit:createUIClass("GameUIBlackSmith", "GameUIUpgradeBuilding")

function GameUIBlackSmith:ctor(city, black_smith,defeat_tab_name)
    GameUIBlackSmith.super.ctor(self, city, _("铁匠铺"), black_smith)
    self.dragon_map = {}
    self.black_smith = black_smith
    self.defeat_tab_name = defeat_tab_name
end
function GameUIBlackSmith:OnMoveInStage()
    GameUIBlackSmith.super.OnMoveInStage(self)
    self.euip_view = GameUIEquip.new(self, self.black_smith)
    self.euip_view:Init()
    self:TabButtons()
end
function GameUIBlackSmith:onExit()
    if self.euip_view then
        self.euip_view:UnInit()
    end
    GameUIBlackSmith.super.onExit(self)
end
function GameUIBlackSmith:TabButtons()
    local tab = self:CreateTabButtons({
        {
            label = _("红龙装备"),
            tag = "redDragon",
            default = self.defeat_tab_name == 'redDragon',
        },
        {
            label = _("蓝龙装备"),
            tag = "blueDragon",
            default = self.defeat_tab_name == 'blueDragon',
        },
        {
            label = _("绿龙装备"),
            tag = "greenDragon",
            default = self.defeat_tab_name == 'greenDragon',
        }
    },
    function(tag)
        if tag == 'upgrade' then
            self.euip_view:HideAll()
        else
            self.euip_view:SwitchToDragon(tag)
            if self.needTips then
                self.needTips = false
                self.euip_view:TriggerTips(tag)
            end
        end
    end):pos(window.cx, window.bottom + 34)

    if not self.defeat_tab_name and self.needTips then
        local dragonType = UtilsForDragon:GetPowerfulDragonType(self.city:GetUser())
        tab:SelectTab(dragonType)
    end
end

return GameUIBlackSmith












