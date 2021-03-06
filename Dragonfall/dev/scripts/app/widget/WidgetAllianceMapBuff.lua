--
-- Author: Kenny Dai
-- Date: 2015-10-29 11:51:54
--
local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetInfo = import(".WidgetInfo")
local WidgetPages = import(".WidgetPages")
local GameUINpc = import("..ui.GameUINpc")
local Localize = import("..utils.Localize")

local aliance_buff = GameDatas.AllianceMap.buff

local WidgetAllianceMapBuff = class("WidgetAllianceMapBuff", WidgetPopDialog)


function WidgetAllianceMapBuff:ctor(mapIndex,needTips)
    WidgetAllianceMapBuff.super.ctor(self,464,_("联盟地图BUFF"))
    local body = self:GetBody()
    local rb_size = body:getContentSize()

    local info_buff = WidgetInfo.new({
        h = 340
    }):align(display.BOTTOM_CENTER, rb_size.width/2 , 30)
        :addTo(body)

    local titles = {}
    for i=1,21 do
        table.insert(titles, string.format(_("第%d圈"),i))
    end
    WidgetPages.new({
        page = 21, -- 页数
        current_page = (DataUtils:getMapRoundByMapIndex(mapIndex) + 1) or 1,
        titles =  titles, -- 标题 type -> table
        cb = function (page)
            info_buff:SetInfo(
                DataUtils:GetAllianceMapBuffByRound(page-1)
            )
        end -- 回调
    }):align(display.CENTER, rb_size.width/2,rb_size.height-50)
        :addTo(body)

    if needTips then
        GameUINpc:PromiseOfSay(
            {npc = "woman", words = _("领主大人，联盟越靠近中心位置，可获得的增益就越多越强，帮助联盟向中心进发吧！")}
        ):next(function()
            return GameUINpc:PromiseOfLeave()
        end)
    end
end

return WidgetAllianceMapBuff

