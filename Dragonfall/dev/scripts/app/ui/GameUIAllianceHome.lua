local window = import("..utils.window")
local Localize = import("..utils.Localize")
local Alliance = import("..entity.Alliance")
local WidgetChat = import("..widget.WidgetChat")
local WidgetChangeMap = import("..widget.WidgetChangeMap")
local WidgetHomeBottom = import("..widget.WidgetHomeBottom")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetAllianceTop = import("..widget.WidgetAllianceTop")
local WidgetMarchEvents = import("app.widget.WidgetMarchEvents")
local WidgetAllianceHelper = import("..widget.WidgetAllianceHelper")
local GameUIAllianceHome = UIKit:createUIClass('GameUIAllianceHome')
local GameUINpc = import("..ui.GameUINpc")
local intInit = GameDatas.AllianceInitData.intInit
local buildingName = GameDatas.AllianceInitData.buildingName
local Alliance_Manager = Alliance_Manager
local cc = cc


function GameUIAllianceHome:DisplayOn()
    self.visible_count = self.visible_count + 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIAllianceHome:DisplayOff()
    self.visible_count = self.visible_count - 1
    self:FadeToSelf(self.visible_count > 0)
end
function GameUIAllianceHome:FadeToSelf(isFullDisplay)
    self:stopAllActions()
    if isFullDisplay then
        self:show()
        transition.fadeIn(self, {
            time = 0.2,
        })
    else
        transition.fadeOut(self, {
            time = 0.2,
            onComplete = function()
                self:hide()
            end,
        })
    end
end
function GameUIAllianceHome:IsDisplayOn()
    return self.visible_count > 0
end


function GameUIAllianceHome:ctor(alliance)
    GameUIAllianceHome.super.ctor(self)
    self.alliance = alliance
end
function GameUIAllianceHome:onEnter()
    GameUIAllianceHome.super.onEnter(self)
    -- 获取历史记录
    self.city = City
    self.visible_count = 1
    self.bottom = self:CreateBottom()

    local ratio = self.bottom:getScale()
    local rect1 = self.chat:getCascadeBoundingBox()
    local x, y = rect1.x, rect1.y + rect1.height - 2

    if app:GetGameDefautlt():IsPassedAllianceFte(1,2,3,4,5)
    and UtilsForFte:NeedTriggerTips(User)
    and not UtilsForEvent:HaveMyMarchEvents()
    and not app:GetGameDefautlt():IsPassedTriggerTips("regionHelps") then
        app:GetGameDefautlt():SetPassTriggerTips("regionHelps")
        self.clipNode = display.newClippingRegionNode(cc.rect(0,0,display.width,80))
                        :addTo(self):pos(x,y)
        local tipsNode = display.newNode():addTo(self.clipNode)
        UIKit:GetPlayerCommonIcon():addTo(tipsNode)
        :scale(0.5):align(display.LEFT_BOTTOM,0,8)
        local sprite = display.newScale9Sprite("word_bubble.png",
                                                rect1.width,
                                                5,
                                                nil,
                                                cc.rect(20,10,10,46))
        :addTo(tipsNode):align(display.RIGHT_BOTTOM):size(545,56)
        UIKit:ttfLabel({
            text = _("大人：\n进攻其他领主有几率获得：英雄之血和龙的装材料"),
            size = 16,
            color = 0xffedae,
        }):addTo(sprite)
        :align(display.LEFT_TOP, 15, 50)
        :setMaxLineWidth(545)
    end

    self.march = WidgetMarchEvents.new(ratio):addTo(self):pos(x, y)
    self:AddMapChangeButton()
    scheduleAt(self, function()
        self:RefreshTop()
        self:UpdateCoordinate(display.getRunningScene():GetSceneLayer():GetMiddlePosition())
    end)
    self:InitArrow()
    -- 中间按钮
    local buttons = UIKit:newWidgetUI("WidgetShortcutButtons",self.city):addTo(self)
    self.order_shortcut = buttons
    buttons.right_top_order:setPositionY(display.top-300)
    local size = buttons.world_map_btn_bg:getCascadeBoundingBox()
    self.loading = display.newSprite("loading.png"):addTo(buttons.world_map_btn_bg)
        :pos(size.width-20,10):scale(0.9)
    self:HideLoading()
    self:AddOrRemoveListener(true)
    self:Schedule()
    -- 促销活动
    local box = ccs.Armature:create("AD_icon"):addTo(self):align(display.CENTER, display.right - 55, display.top - 205)
    box:getAnimation():playWithIndex(0)
    self.promotionTime = UIKit:ttfLabel({
        text = GameUtils:formatTimeStyle1(DataUtils:GetPromtionProductLessLeftTime()),
        size = 16,
        color = 0xffedae,
        shadow = true
    }):align(display.CENTER, display.right - 55, display.top - 227)
        :addTo(self)
    local sale_button = WidgetPushButton.new()
        :addTo(self):align(display.CENTER, display.right - 55, display.top - 205)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                UIKit:newGameUI("GameUISaleOne"):AddToCurrentScene()
            end
        end)
    sale_button:setContentSize(cc.size(100,110))
    sale_button:setTouchSwallowEnabled(true)
    if UtilsForFte:NeedTriggerTips(User)
    and not app:GetGameDefautlt():IsPassedTriggerTips("allianceFight") then
        local status = self.alliance.basicInfo.status
        if (status == "fight" or status == "prepare")
            and self.self_power_label
            and self.enemy_power_label then
            app:GetGameDefautlt():SetPassTriggerTips("allianceFight")
            local node = display.newNode():addTo(self,100)
            local rect1 = self.self_power_label:getCascadeBoundingBox()
            local src = cc.p(rect1.x + 130, rect1.y - 25)
            local rect2 = self.enemy_power_label:getCascadeBoundingBox()
            local dst = cc.p(rect2.x + 130, rect2.y - 25)
            local r1 = self.self_power_label:getParent():getCascadeBoundingBox()
            local r2 = self.enemy_power_label:getParent():getCascadeBoundingBox()
            GameUINpc:PromiseOfSay({
                words = _("领主大人，您正在参与一场联盟战！")
            }):next(function()
                UIKit:FingerAni():addTo(node,10,111):pos(src.x,src.y)
                return GameUINpc:PromiseOfSay({
                            focus_rect = cc.rectUnion( r1, r2 ),
                            words = _("左上方为我方联盟击杀数量")
                        })
            end):next(function()
                local finger = node:getChildByTag(111)
                finger:moveTo(0.6, dst.x, dst.y)
                return GameUINpc:PromiseOfSay({
                            focus_rect = cc.rectUnion( r1, r2 ),
                            words = _("右上方为敌方联盟击杀数量")
                        })
            end):next(function()
                node:removeFromParent()
                return GameUINpc:PromiseOfSay({
                    focus_rect = cc.rectUnion( r1, r2 ),
                    words = _("攻击敌方城市或防御敌方部队来袭，均可获得击杀积分，联盟战结束时，击杀积分高的一方将获得最后的胜利！")
                })
            end):next(function()
                return GameUINpc:PromiseOfLeave()
            end)
        end
    end
end
function GameUIAllianceHome:onExit()
    self:AddOrRemoveListener(false)
    GameUIAllianceHome.super.onExit(self)
end
function GameUIAllianceHome:GetShortcutNode()
    return self.order_shortcut
end
function GameUIAllianceHome:AddOrRemoveListener(isAdd)
    local alliance = self.alliance
    if isAdd then
        alliance:AddListenOnType(self, "basicInfo")
        alliance:AddListenOnType(self, "allianceFight")
        Alliance_Manager:AddHandle(self)
    else
        alliance:RemoveListenerOnType(self, "basicInfo")
        alliance:RemoveListenerOnType(self, "allianceFight")
        Alliance_Manager:RemoveHandle(self)
    end
end
function GameUIAllianceHome:ShowLoading()
    if self.loading:isVisible() and
        self.loading:getNumberOfRunningActions() > 0 then
        return
    end
    self.loading:show():rotation(math.random(360)):stopAllActions()
    self.loading:runAction(cc.RepeatForever:create(cc.RotateBy:create(4, 360)))
    display.newNode():addTo(self):runAction(transition.sequence{
        cc.DelayTime:create(10),
        cc.CallFunc:create(function()
            self:HideLoading()
        end),
        cc.RemoveSelf:create(),
    })
end
function GameUIAllianceHome:HideLoading()
    self.loading:hide():stopAllActions()
end
function GameUIAllianceHome:AddMapChangeButton()
    WidgetChangeMap.new(WidgetChangeMap.MAP_TYPE.OUR_ALLIANCE):addTo(self)
end
function GameUIAllianceHome:OnMapDataChanged()
end
function GameUIAllianceHome:OnMapAllianceChanged()
    self:RefreshTop(true)
end

function GameUIAllianceHome:OnAllianceDataChanged_basicInfo(alliance,deltaData)
    local ok_honour, new_honour = deltaData("basicInfo.honour")
    local ok_status, new_status = deltaData("basicInfo.status")
    local ok_name, new_name = deltaData("basicInfo.name")
    local ok_tag, new_tag = deltaData("basicInfo.tag")
    local ok_flag, new_flag = deltaData("basicInfo.flag")
    if ok_honour then
        self.page_top:SetHonour(GameUtils:formatNumber(new_honour))
    elseif ok_status then
        if alliance.allianceFightReports then
            NetManager:getAllianceFightReportsPromise(self.alliance.id):done(function ( ... )
                self:RefreshTop()
            end)
        else
            self:RefreshTop()
        end
    elseif ok_name or ok_tag then
        self:RefreshTop(true)
    elseif ok_flag then
        self:RefreshTop(true)
    end

    if deltaData("basicInfo.status", "fight") then
        self:RefreshTop()
    end
end
function GameUIAllianceHome:OnAllianceDataChanged_allianceFight(alliance,deltaData)
    self:RefreshTop(true)
end
function GameUIAllianceHome:Schedule()
    scheduleAt(self, function()
        if self.alliance:IsDefault() then return end
        self:UpdateMyCityArrows(self.alliance)
        self:UpdateEnemyArrow()
    end, 0.01)
    display.newNode():addTo(self):schedule(function()
        if self.alliance:IsDefault() then return end
        local mapIndex = self.alliance:GetEnemyAllianceMapIndex()
        if not mapIndex then
            for i,v in ipairs(self.enemy_arrows) do
                v:hide()
            end
            return
        end
        self:UpdateEnemyCityArrows()
    end, 0.05)
end

function GameUIAllianceHome:InitArrow()
    self.enemy_arrows = {}
    for i = 1, 5 do
        self.enemy_arrows[i] =
            display.newSprite("arrow_red-hd.png")
                :addTo(self, 10):align(display.TOP_CENTER):hide()
    end
    self.enemy_arrow_index = 1

    self.arrow_enemy = UIKit:CreateArrow({
        circle = "arrow_circle_enemy.png",
        up = "arrow_up_enemy.png",
        down = "arrow_down_enemy.png",
        icon = "attack_58x56.png",
    }, function()
        local mapIndex = Alliance_Manager:GetMyAlliance():GetEnemyAllianceMapIndex()
        if not mapIndex then return self.arrow_enemy:hide() end
        local scene = display.getRunningScene()
        if Alliance_Manager:GetAllianceByCache(mapIndex) then
            if scene.GetSceneLayer then
                scene:GotoAllianceByXY(scene:GetSceneLayer():IndexToLogic(mapIndex))
            end
        else
            if scene.GetSceneLayer then
                scene:FetchAllianceDatasByIndex(mapIndex, function()
                    scene:GotoAllianceByXY(scene:GetSceneLayer():IndexToLogic(mapIndex))
                end)
            end
        end
    end):addTo(self, 10):align(display.TOP_CENTER):hide()
    if device.platform ~= 'winrt' then
        self.arrow_enemy:scale(0.8)
    end
    self.arrow_enemy.icon:scale(0.68)

    self.arrow = UIKit:CreateArrow({}, function()
        self:ReturnMyCity()
    end):addTo(self, 10):align(display.TOP_CENTER):hide()
    if device.platform ~= 'winrt' then
        self.arrow:scale(0.8)
    end
end
function GameUIAllianceHome:GetScreenRect()
    local rect1 = self.march:getCascadeBoundingBox()
    local rect2 = self.top_bg:getCascadeBoundingBox()
    return cc.rect(0, rect1.y + rect1.height, display.width, rect2.y - (rect1.y + rect1.height))
end
function GameUIAllianceHome:ReturnMyCity()
    local alliance = self.alliance
    local mapObject = alliance:FindMapObjectById(alliance:GetSelf().mapId)
    local location = mapObject.location
    local x,y = DataUtils:GetAbsolutePosition(alliance.mapIndex, location.x, location.y)
    display.getRunningScene():GotoPosition(x,y)
end

function GameUIAllianceHome:TopBg()
    local top_bg = display.newSprite("top_bg_768x116.png")
        :align(display.TOP_CENTER, window.cx, window.top)
        :addTo(self)
    if display.width >640 then
        top_bg:scale(display.width/768)
    end
    top_bg:setTouchEnabled(true)
    self.top_bg = top_bg

    top_bg:setTouchSwallowEnabled(true)
    local t_size = top_bg:getContentSize()
    local alliance = self.alliance
    local status = alliance.basicInfo.status
    local left_img,right_img,mid_img
    if status == "fight" or status == "prepare" then
        left_img = {normal = "button_blue_normal_314X88.png",
            pressed = "button_blue_pressed_314X88.png"}
        right_img = {normal = "button_red_normal_314X88.png",
            pressed = "button_red_pressed_314X88.png"}
    else
        if self.current_allinace_index and self.current_allinace_index ~= alliance.mapIndex then
            left_img = {normal = "button_red_normal_388X86.png",
                pressed = "button_red_pressed_388X86.png"}
        else
            left_img = {normal = "button_blue_normal_388X86.png",
                pressed = "button_blue_pressed_388X86.png"}
        end
        right_img = {normal = "button_blue_normal_240X86.png",
            pressed = "button_blue_pressed_240X86.png"}
        mid_img = "background_52x112.png"
    end


    -- 顶部背景,为按钮
    local top_self_bg = WidgetPushButton.new(left_img)
        :onButtonClicked(handler(self, self.OnTopLeftButtonClicked))
        :align(display.TOP_LEFT, 69, t_size.height-4)
        :addTo(top_bg)
    local top_enemy_bg = WidgetPushButton.new(right_img)
        :onButtonClicked(handler(self, self.OnTopRightButtonClicked))
        :align(display.TOP_RIGHT, t_size.width - 69, t_size.height-4)
        :addTo(top_bg)
    if mid_img then
        display.newSprite(mid_img):align(display.TOP_CENTER,t_size.width-240-26 - 44,t_size.height):addTo(top_bg)
    end

    return top_self_bg,top_enemy_bg,top_bg
end

function GameUIAllianceHome:TopTabButtons()
    self.page_top = WidgetAllianceTop.new(self.alliance):align(display.TOP_CENTER,self.top_bg:getContentSize().width/2,26)
        :addTo(self.top_bg)
end

function GameUIAllianceHome:RefreshTop(force_refresh)
    if self.alliance:IsDefault() then return end
    local alliance = self.alliance
    -- 获取当前所在联盟
    local current_allinace_index = self.current_allinace_index
    local pre_status = self.pre_status
    local need_refresh = false
    local current_map_index = display.getRunningScene():GetSceneLayer():GetMiddleAllianceIndex()
    local need_refresh = current_allinace_index ~= current_map_index or pre_status ~= alliance.basicInfo.status
    if not need_refresh and not force_refresh then
        return
    end
    self.current_allinace_index = current_map_index
    self.pre_status = alliance.basicInfo.status
    local isMyAlliance = current_map_index == alliance.mapIndex
    local top_bg = self.top_bg
    if top_bg then
        top_bg:removeFromParent()
    end
    local current_alliance = Alliance_Manager:GetAllianceByCache(current_map_index)
    local Top = {}
    local top_self_bg,top_enemy_bg,top_bg = self:TopBg()
    local top_self_size = top_self_bg:getCascadeBoundingBox().size
    local top_enemy_size = top_enemy_bg:getCascadeBoundingBox().size
    if alliance.basicInfo.status == "fight"
    or alliance.basicInfo.status == "prepare" then
        -- 己方联盟名字
        local self_name_bg = display.newSprite("title_green_292X32.png")
            :align(display.LEFT_CENTER, 0,-26)
            :addTo(top_self_bg):flipX(true)
        self.self_name_bg = self_name_bg
        self.self_name_label = UIKit:ttfLabel(
            {
                text = "["..alliance.basicInfo.tag.."] "..alliance.basicInfo.name,
                size = 18,
                color = 0xffedae,
                dimensions = cc.size(160,18),
                ellipsis = true
            }):align(display.LEFT_CENTER, 30, 20)
            :addTo(self_name_bg)
        -- 己方联盟旗帜
        local ui_helper = WidgetAllianceHelper.new()
        local self_flag = ui_helper:CreateFlagContentSprite(alliance.basicInfo.flag):scale(0.5)
        self_flag:align(display.CENTER, self_name_bg:getContentSize().width-100, -30):addTo(self_name_bg)
        self.self_flag = self_flag

        -- 和平期,战争期,准备期背景
        local period_bg = WidgetPushButton.new({normal = "box_104x104.png"})
            :onButtonClicked(function (event)
                if event.name == "CLICKED_EVENT" then
                    UIKit:newWidgetUI("WidgetWarIntroduce"):AddToCurrentScene(true)
                end
            end)
            :align(display.TOP_CENTER, top_bg:getContentSize().width/2,top_bg:getContentSize().height)
            :addTo(top_bg)
        period_bg:setTouchSwallowEnabled(true)

        local period_text = self:GetAlliancePeriod()
        local period_label = UIKit:ttfLabel(
            {
                text = period_text,
                size = 16,
                color = 0xbdb582
            }):align(display.TOP_CENTER, period_bg:getContentSize().width/2, period_bg:getContentSize().height-14)
            :addTo(period_bg)
        local time_label = UIKit:ttfLabel(
            {
                text = "",
                size = 18,
                color = 0xffedae
            }):align(display.BOTTOM_CENTER, period_bg:getContentSize().width/2, period_bg:getContentSize().height/2-62)
            :addTo(period_bg)
        scheduleAt(period_bg, function()
            local basicInfo = alliance.basicInfo
            if basicInfo.status then
                local statusFinishTime = basicInfo.statusFinishTime
                if math.floor(statusFinishTime/1000)>app.timer:GetServerTime() then
                    time_label:setString(GameUtils:formatTimeStyle1(math.floor(statusFinishTime/1000)-app.timer:GetServerTime()))
                end
            end
        end)

        -- 敌方联盟名字 或者 占领联盟背景条
        local enemy_alliance = alliance.allianceFight.attacker.alliance.id == alliance._id and alliance.allianceFight.defencer or alliance.allianceFight.attacker
        local enemy_name_bg =  display.newSprite("title_red_292X32.png")
            :align(display.RIGHT_CENTER, 0,-26)
            :addTo(top_enemy_bg)
        local enemy_name_label = UIKit:ttfLabel(
            {
                text = enemy_alliance.alliance.name,
                size = 18,
                color = 0xffedae,
                dimensions = cc.size(160,18),
                ellipsis = true
            }):align(display.LEFT_CENTER, 100, 20)
            :addTo(enemy_name_bg)

        local our_kill = alliance.allianceFight.attacker.alliance.id == alliance._id and alliance.allianceFight.attacker.allianceCountData.kill or alliance.allianceFight.defencer.allianceCountData.kill
        local enemy_kill = alliance.allianceFight.attacker.alliance.id == alliance._id and alliance.allianceFight.defencer.allianceCountData.kill or alliance.allianceFight.attacker.allianceCountData.kill
        -- 己方击杀
        local self_power_bg = display.newSprite("power_background_146x26.png")
            :align(display.LEFT_CENTER, 40, -65):addTo(top_self_bg)
        local our_num_icon = cc.ui.UIImage.new("battle_33x33.png"):align(display.CENTER, 40, -65):addTo(top_self_bg)
        local self_power_label = UIKit:ttfLabel(
            {
                text = string.formatnumberthousands(our_kill),
                size = 20,
                color = 0xbdb582
            }):align(display.LEFT_CENTER, 20, self_power_bg:getContentSize().height/2)
            :addTo(self_power_bg)
        self.self_power_label = self_power_label

        enemy_name_label:setString("["..enemy_alliance.alliance.tag.."] "..enemy_alliance.alliance.name)
        local enemy_flag = ui_helper:CreateFlagContentSprite(enemy_alliance.alliance.flag):scale(0.5)
        enemy_flag:align(display.CENTER,100-enemy_flag:getCascadeBoundingBox().size.width, -30)
            :addTo(enemy_name_bg)

        -- 敌方击杀
        local enemy_power_bg = display.newSprite("power_background_red_146x26.png")
            :align(display.RIGHT_CENTER, -20, -65):addTo(top_enemy_bg)
        local enemy_num_icon = cc.ui.UIImage.new("battle_33x33.png")
            :align(display.CENTER, 0, enemy_power_bg:getContentSize().height/2)
            :addTo(enemy_power_bg)
        local enemy_power_label = UIKit:ttfLabel(
            {
                text = string.formatnumberthousands(enemy_kill),
                size = 20,
                color = 0xbdb582
            }):align(display.LEFT_CENTER, 20, enemy_power_bg:getContentSize().height/2)
            :addTo(enemy_power_bg)
        self.enemy_power_label = enemy_power_label
        -- end
    else
        local isKing = DataUtils:getMapRoundByMapIndex(current_map_index) == 0 -- 是否在王座
        local name_bg = display.newSprite("title_red_266x32.png"):align(display.LEFT_CENTER, 10,- 28):addTo(top_self_bg)
        local flag_bg = display.newSprite(isMyAlliance and "background_flag_mine_100x86.png" or "background_flag_enemy_100x86.png"):align(display.LEFT_CENTER, -10, -top_self_size.height/2 - 4):addTo(top_self_bg)
        -- 联盟旗帜
        if current_alliance then
            local ui_helper = WidgetAllianceHelper.new()
            local self_flag = ui_helper:CreateFlagContentSprite(current_alliance.basicInfo.flag):scale(0.6)
            self_flag:align(display.CENTER, 15,7):addTo(flag_bg)
        else
            display.newSprite("icon_unknown_72x86.png"):align(display.CENTER, flag_bg:getContentSize().width/2,flag_bg:getContentSize().height/2):addTo(flag_bg)
        end
        if isKing then
            flag_bg:hide()
            local crown_icon = display.newSprite("crystalThrone.png")
                :align(display.LEFT_CENTER, -10, -top_self_size.height/2)
                :addTo(top_self_bg)
                :scale(0.14)
        end
        local alliance_name_label = UIKit:ttfLabel(
            {
                text = current_alliance and current_alliance.basicInfo.name or (isKing and _("水晶王座") or _("无主之地")),
                size = 18,
                color = 0xffedae,
                dimensions = cc.size(160,18),
                ellipsis = true
            }):align(display.LEFT_CENTER, 80, 20)
            :addTo(name_bg)
        local text_1,isAddAction
        if current_alliance then
            if current_alliance.mapIndex == self.alliance.mapIndex then
                text_1 = _("战争历史")
            else
                text_1 = _("宣战")
                isAddAction = true
            end
        else
            text_1 = isKing and _("宣战") or _("迁移联盟")
            isAddAction = true
        end
        local action_label = UIKit:ttfLabel(
            {
                text = text_1,
                size = 20,
                color = 0xbdb582,
            }):align(display.LEFT_CENTER, flag_bg:getPositionX() + flag_bg:getContentSize().width,flag_bg:getPositionY() - 20):addTo(top_self_bg)
        if isAddAction then
            action_label:runAction(
                cc.RepeatForever:create(
                    transition.sequence{
                        cc.ScaleTo:create(0.5, 1.1),
                        cc.ScaleTo:create(0.5, 1.0),
                    }
                )
            )
        end

        local period_bg = display.newSprite("background_98x70.png"):align(display.LEFT_CENTER, name_bg:getPositionX() + name_bg:getContentSize().width + 10,-top_self_size.height/2 - 4):addTo(top_self_bg)
        UIKit:ttfLabel({
            text = isKing and _("和平期") or current_alliance and Localize.period_type[current_alliance.basicInfo.status] or _("迁移冷却"),
            size = 16,
            color = 0xbdb582
        }):align(display.CENTER, period_bg:getContentSize().width/2, period_bg:getContentSize().height - 20):addTo(period_bg)

        local period_time_label = UIKit:ttfLabel({
            text = "",
            size = 18,
            color = 0xe34724
        }):align(display.CENTER, period_bg:getContentSize().width/2, 22):addTo(period_bg)

        scheduleAt(period_bg, function()
            if isKing then
                period_time_label:setString(_("无"))
                period_time_label:setColor(UIKit:hex2c4b(0xa1dd00))
            else
                if current_alliance then
                    local basicInfo = current_alliance.basicInfo
                    period_time_label:setColor(basicInfo.status ~= "peace" and UIKit:hex2c4b(0xe34724) or UIKit:hex2c4b(0xa1dd00))
                    if basicInfo.status then
                        if basicInfo.status ~= "peace" then
                            local statusFinishTime = basicInfo.statusFinishTime
                            if math.floor(statusFinishTime/1000)>app.timer:GetServerTime() then
                                period_time_label:setString(GameUtils:formatTimeStyle1(math.floor(statusFinishTime/1000)-app.timer:GetServerTime()))
                            end
                        else
                            local statusStartTime = basicInfo.statusStartTime
                            if app.timer:GetServerTime()>= math.floor(statusStartTime/1000) then
                                period_time_label:setString(GameUtils:formatTimeStyle1(app.timer:GetServerTime()-math.floor(statusStartTime/1000)))
                            end
                        end
                    end
                else
                    local time = intInit.allianceMoveColdMinutes.value * 60 + Alliance_Manager:GetMyAlliance().basicInfo.allianceMoveTime/1000.0 - app.timer:GetServerTime()
                    local canMove = Alliance_Manager:GetMyAlliance().basicInfo.allianceMoveTime == 0 or time <= 0
                    period_time_label:setString(canMove and _("准备就绪") or GameUtils:formatTimeStyle1(time))
                    period_time_label:setColor(canMove and UIKit:hex2c4b(0xa1dd00) or UIKit:hex2c4b(0xe34724))
                end
            end
        end)

        -- right part 圈数，对应buff
        local round_bg = display.newScale9Sprite("background_98x70.png",0 , 0,cc.size(190,28),cc.rect(15,10,68,50))
            :align(display.RIGHT_TOP,-24,-12)
            :addTo(top_enemy_bg)
        if isKing then
            display.newSprite("icon_unknown_72x86.png"):align(display.LEFT_CENTER, -10,14):addTo(round_bg):scale(0.4)
        else
            if device.platform == 'winrt' then
                display.newSprite("icon_world_28x38.png"):align(display.LEFT_CENTER, -10,14):addTo(round_bg)
            else
                display.newSprite("icon_world_88x88.png"):align(display.LEFT_CENTER, -10,14):addTo(round_bg):scale(0.4)
            end
        end
        UIKit:ttfLabel({
            text = isKing and "" or _("圈数"),
            size = 18,
            color = 0xffedae
        }):align(display.LEFT_CENTER, 30, 14):addTo(round_bg)
        UIKit:ttfLabel({
            text = isKing and _("无") or DataUtils:getMapRoundByMapIndex(current_map_index) + 1,
            size = 20,
            color = isKing and 0xffedae or 0xa1dd00
        }):align(display.RIGHT_CENTER, 180, 14):addTo(round_bg)

        local buff_bg = display.newScale9Sprite("background_98x70.png",0 , 0,cc.size(190,28),cc.rect(15,10,68,50))
            :align(display.RIGHT_TOP,-24,-50)
            :addTo(top_enemy_bg)
        UIKit:ttfLabel({
            text = isKing and "" or _("增益数量"),
            size = 18,
            color = 0xffedae
        }):align(display.LEFT_CENTER,30, 14):addTo(buff_bg)
        UIKit:ttfLabel({
            text = isKing and _("无") or DataUtils:getMapBuffNumByMapIndex(current_map_index),
            size = 20,
            color = isKing and 0xffedae or 0xa1dd00
        }):align(display.RIGHT_CENTER, 180, 14):addTo(buff_bg)
        if isKing then
            display.newSprite("icon_crown_110x94.png"):align(display.LEFT_CENTER, -10,14):addTo(buff_bg):scale(0.3)
        else
            if device.platform == 'winrt' then
                display.newSprite("buff_28x28.png"):align(display.LEFT_CENTER, -5,14):addTo(buff_bg)
            else
                display.newSprite("buff_68x68.png"):align(display.LEFT_CENTER, -5,14):addTo(buff_bg):scale(0.4)
            end
        end
    end
    self:TopTabButtons()
end
function GameUIAllianceHome:CreateBottom()
    local bottom_bg = WidgetHomeBottom.new(self.city):addTo(self)
        :align(display.BOTTOM_CENTER, display.cx, display.bottom)
    self.chat = WidgetChat.new():addTo(bottom_bg)
        :align(display.CENTER, bottom_bg:getContentSize().width/2, bottom_bg:getContentSize().height)
    return bottom_bg
end
function GameUIAllianceHome:ChangeChatChannel(channel_index)
    self.chat:ChangeChannel(channel_index)
end
function GameUIAllianceHome:OnTopLeftButtonClicked(event)
    if event.name == "CLICKED_EVENT" then
        if self.alliance.basicInfo.status == "fight" or self.alliance.basicInfo.status == "prepare" then
            UIKit:newGameUI("GameUIAllianceBattle", self.city , "fight"):AddToCurrentScene(true)
        else
            local current_allinace_index = self.current_allinace_index
            if current_allinace_index and self.alliance.mapIndex ~= current_allinace_index then
                local current_alliance = Alliance_Manager:GetAllianceByCache(current_allinace_index)
                if current_alliance then
                    UIKit:newGameUI("GameUIAllianceBattle", self.city , "fight" ,current_alliance):AddToCurrentScene(true)
                else
                    if DataUtils:getMapRoundByMapIndex(current_allinace_index) == 0 then -- 王座
                        UIKit:newGameUI("GameUIThroneMain"):AddToCurrentScene()
                    else
                        UIKit:newWidgetUI("WidgetWorldAllianceInfo",nil,current_allinace_index):AddToCurrentScene()
                    end
                end
            else
                UIKit:newGameUI("GameUIAllianceBattle", self.city , "history"):AddToCurrentScene(true)
            end
        end
    end
end
function GameUIAllianceHome:OnTopRightButtonClicked(event)
    if event.name == "CLICKED_EVENT" then
        if self.alliance.basicInfo.status == "fight" or self.alliance.basicInfo.status == "prepare" then
            UIKit:newGameUI("GameUIAllianceBattle", self.city , "fight"):AddToCurrentScene(true)
        else
            local isKing = DataUtils:getMapRoundByMapIndex(self.current_allinace_index) == 0 -- 是否在王座
            if isKing then
                UIKit:showMessageDialog(_("提示"), _("即将开放"))
            else
                UIKit:newWidgetUI("WidgetAllianceMapBuff",self.current_allinace_index):AddToCurrentScene()
            end
        end
    end
end
local deg = math.deg
local ceil = math.ceil
local point = cc.p
local pSub = cc.pSub
local pGetAngle = cc.pGetAngle
local pGetLength = cc.pGetLength
local rectContainsPoint = cc.rectContainsPoint
local RIGHT_CENTER = display.RIGHT_CENTER
local LEFT_CENTER = display.LEFT_CENTER
local MID_POINT = point(display.cx, display.cy)
local function pGetIntersectPoint(pt1,pt2,pt3,pt4)
    local s,t, ret = 0,0,false
    ret,s,t = cc.pIsLineIntersect(pt1,pt2,pt3,pt4,s,t)
    if ret then
        return point(pt1.x + s * (pt2.x - pt1.x), pt1.y + s * (pt2.y - pt1.y)), s
    else
        return point(0,0), s
    end
end
function GameUIAllianceHome:UpdateCoordinate(logic_x, logic_y, alliance_view)
    local coordinate_str = string.format("%d, %d", logic_x, logic_y)
    local is_mine
    if alliance_view then
        is_mine = alliance_view:GetAlliance().id == self.alliance.id and _("我方") or _("敌方")
    else
        is_mine = _("坐标")
    end
    self.page_top:SetCoordinateTitle(is_mine)
    self.page_top:SetCoordinate(coordinate_str)
end
function GameUIAllianceHome:UpdateMyCityArrows(alliance)
    local screen_rect = self:GetScreenRect()
    local member = alliance:GetSelf()
    local mapObj = alliance:FindMapObjectById(member.mapId)
    local x,y = DataUtils:GetAbsolutePosition(alliance.mapIndex, mapObj.location.x, mapObj.location.y)
    local sceneLayer = display.getRunningScene():GetSceneLayer()
    local map_point = sceneLayer:ConvertLogicPositionToMapPosition(x,y)
    local world_point = sceneLayer:convertToWorldSpace(map_point)
    if not rectContainsPoint(screen_rect, world_point) then
        local p,degree = self:GetIntersectPoint(screen_rect, MID_POINT, world_point)
        if p and degree then
            degree = degree + 180
            self.arrow:show():pos(p.x, p.y):rotation(degree)
            self.arrow.btn:rotation(-degree)
            self.arrow.icon:rotation(-degree)
        end
    else
        self.arrow:hide()
    end
end
function GameUIAllianceHome:UpdateEnemyArrow()
    local mapIndex = self.alliance:GetEnemyAllianceMapIndex()
    if not mapIndex then
        return self.arrow_enemy:hide()
    end
    local screen_rect = self:GetScreenRect()
    local x,y = DataUtils:GetAbsolutePosition(mapIndex, 16, 16)
    local sceneLayer = display.getRunningScene():GetSceneLayer()
    local map_point = sceneLayer:ConvertLogicPositionToMapPosition(x,y)
    local world_point = sceneLayer:convertToWorldSpace(map_point)
    if not rectContainsPoint(screen_rect, world_point) then
        local p,degree = self:GetIntersectPoint(screen_rect, MID_POINT, world_point)
        if p and degree then
            degree = degree + 180
            self.arrow_enemy:show():pos(p.x, p.y):rotation(degree)
            self.arrow_enemy.btn:rotation(-degree)
            self.arrow_enemy.icon:rotation(-degree)
            if pGetLength(pSub(world_point, p)) < 700 then
                self.arrow_enemy:hide()
            end
        end
    else
        self.arrow_enemy:hide()
    end
end

local min = math.min
local MAX_ARROW_COUNT = 5
function GameUIAllianceHome:UpdateFriendArrows(screen_rect, alliance, layer, logic_x, logic_y, myself)
    local count = self:UpdateAllianceArrow(screen_rect, alliance, layer, logic_x, logic_y, self.friends_arrow_index, function(index)
        if not self.friends_arrows[index] then
            self.friends_arrows[index] = display.newSprite("arrow_blue-hd.png")
                :addTo(self, -2):align(display.TOP_CENTER):hide()
        end
        return self.friends_arrows[index]
    end, myself:MapId())
    local friends_arrows = self.friends_arrows
    for i = count, #friends_arrows do
        friends_arrows[i]:hide()
    end
    self.friends_arrow_index = self.friends_arrow_index + 1
    if self.friends_arrow_index > min(count, MAX_ARROW_COUNT) then
        self.friends_arrow_index = 1
    end
end
function GameUIAllianceHome:UpdateEnemyCityArrows()
    local mapIndex = self.alliance:GetEnemyAllianceMapIndex()
    if not mapIndex then return end
    local alliance = Alliance_Manager:GetAllianceByCache(mapIndex)
    if not alliance then return end

    local screen_rect = self:GetScreenRect()
    local sceneLayer = display.getRunningScene():GetSceneLayer()
    local count = 1
    Alliance.IteratorCities(alliance, function(_, v)
        if count > MAX_ARROW_COUNT then return true end
        local arrow = self.enemy_arrows[count]
        if count == self.enemy_arrow_index then
            local x,y = DataUtils:GetAbsolutePosition(mapIndex, v.location.x, v.location.y)
            local map_point = sceneLayer:ConvertLogicPositionToMapPosition(x,y)
            local world_point = sceneLayer:convertToWorldSpace(map_point)
            if not rectContainsPoint(screen_rect, world_point) then
                local p,degree = self:GetIntersectPoint(screen_rect, MID_POINT, world_point)
                if p and degree then
                    degree = degree + 180
                    arrow:pos(p.x, p.y):rotation(degree)
                    if pGetLength(pSub(world_point, p)) < 1400 then
                        arrow:show()
                    end
                end
            else
                arrow:hide()
            end
        end
        count = count + 1
    end)

    self.enemy_arrow_index = self.enemy_arrow_index + 1
    if self.enemy_arrow_index > MAX_ARROW_COUNT then
        self.enemy_arrow_index = 1
    end
end
--
function GameUIAllianceHome:UpdateAllianceArrow(screen_rect, alliance, layer, logic_x, logic_y, cur_index, func, except_map_id)
    local id = alliance.id
    local count = 1
    alliance:IteratorCities(function(_, v)
        if count > MAX_ARROW_COUNT then return true end
        if count == cur_index and except_map_id ~= v.id then
            local x,y = v:GetMidLogicPosition()
            local dx, dy = (logic_x - x), (logic_y - y)
            if dx^2 + dy^2 > 1 then
                local arrow = func(count)
                local map_point = layer:ConvertLogicPositionToMapPosition(x, y, id)
                local world_point = layer:convertToWorldSpace(map_point)
                if not rectContainsPoint(screen_rect, world_point) then
                    local p,degree = self:GetIntersectPoint(screen_rect, MID_POINT, world_point)
                    if p and degree then
                        arrow:show():pos(p.x, p.y):rotation(degree + 180)
                    end
                else
                    arrow:hide()
                end
            end
        end
        count = count + 1
    end)
    return count
end
--
function GameUIAllianceHome:GetIntersectPoint(screen_rect, point1, point2, normal)
    local points = self:GetPointsWithScreenRect(screen_rect)
    for i = 1, #points do
        local p1, p2
        if i ~= #points then
            p1 = points[i]
            p2 = points[i + 1]
        else
            p1 = points[i]
            p2 = points[1]
        end
        local p,s = pGetIntersectPoint(point1, point2, p1, p2)
        if s > 0 and rectContainsPoint(screen_rect, p) then
            return p, deg(pGetAngle(pSub(point1, point2), normal or point(0, 1)))
        end
    end
end
function GameUIAllianceHome:GetPointsWithScreenRect(screen_rect)
    local x,y,w,h = screen_rect.x, screen_rect.y, screen_rect.width, screen_rect.height
    return {
        point(x + w, y),
        point(x + w, y + h),
        point(x, y + h),
        point(x, y),
    }
end

function GameUIAllianceHome:GetAlliancePeriod()
    local period = ""
    local status = self.alliance.basicInfo.status
    if status == "peace" then
        period = _("和平期")
    elseif status == "prepare" then
        period = _("准备期")
    elseif status == "fight" then
        period = _("战争期")
    elseif status == "protect" then
        period = _("保护期")
    end
    return period
end


local WidgetFteArrow = import("..widget.WidgetFteArrow")
local WidgetFteMark = import("..widget.WidgetFteMark")
local UILib = import("..ui.UILib")
local FTE_TAG = 10018
function GameUIAllianceHome:ShowHonorFte(isshow)
    self:removeChildByTag(FTE_TAG)
    if not isshow then
        self.page_top:EnableAnimation(true)
        return
    end
    self.page_top:EnableAnimation(false)
    local fteNode = display.newNode():addTo(self,10,FTE_TAG)
    local r = self.page_top.honour_btn:getCascadeBoundingBox()
    local mark = WidgetFteMark.new():addTo(fteNode)
    :size(r.width+30, r.height+30)
    :pos(r.x + r.width/2, r.y + r.height/2)

    local content = display.newNode()
    local totalsize = 0
    local maxheight = 0
    for i,v in ipairs({
        UILib.resource.iron,
        UILib.resource.food,
        UILib.resource.wood,
        UILib.resource.coin,
        UILib.resource.stone,
        UILib.resource.gem,
    }) do
        local scale = UILib.resource.gem ~= v and 0.5 or 0.8
        local sprite = display.newSprite(v):addTo(content)
        :align(display.LEFT_CENTER,totalsize,0):scale(scale)
        local size = sprite:getContentSize()
        if maxheight < size.height * scale then
            maxheight = size.height * scale
        end
        totalsize = totalsize + size.width * scale + 15
    end
    content:setContentSize(cc.size(totalsize-15,maxheight))
    WidgetFteArrow.new(content):TurnUp(false):addTo(fteNode):scale(0.8)
    :pos(r.x + r.width/2+(totalsize-15)/2, r.y - r.height/2 - maxheight + 35)
end
function GameUIAllianceHome:ShowWorldMap(isshow)
    self:GetShortcutNode().world_map_btn:removeChildByTag(FTE_TAG)
    if not isshow then
        return
    end
    self:GetShortcutNode().world_map_btn:onButtonClicked(function()
        self:ShowWorldMap()
    end)
    WidgetFteArrow.new(_("世界地图")):TurnLeft()
    :addTo(self:GetShortcutNode().world_map_btn,100,FTE_TAG)
    :pos(200,0)

end

return GameUIAllianceHome




