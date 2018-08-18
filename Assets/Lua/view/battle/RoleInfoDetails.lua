local roleinfo_details = {}

local proofread = 25
local Screen_width = 0
local detail_width = 0
local x_while_left = 0
local x_while_right = 0
local animate_time = 0.15


local skilltype_list = {
    [1] = "物攻",
    [2] = "法攻",
    [3] = "治疗",
    [4] = "护盾",
    [5] = "召唤",
    [6] = "削弱",
    [7] = "强化",
    [11] = "单体",
    [12] = "群体"
}

function roleinfo_details:Start()
    self.view = SGK.UIReference.Setup(self.gameObject)
    Screen_width = self.view[UnityEngine.RectTransform].rect.width
    detail_width = self.view.otherdetail[UnityEngine.RectTransform].rect.width

    x_while_left = -(Screen_width/2 - detail_width/2) + proofread
    x_while_right = (Screen_width/2 - detail_width/2) - proofread
end

function roleinfo_details:UpdateSkillDetails(click_pos, info)
    if type(info) ~= "table" then
        return
    end

    local skilldetail = self.view.skilldetail

    --[[
    skilldetail.name.Text[UnityEngine.UI.Text].text = info.name
    skilldetail.cost.Text[UnityEngine.UI.Text].text = ("消耗法力值"..info.cost.."点")
    skilldetail.type.type1[CS.UGUISpriteSelector].index = info.skilltype - 1
    skilldetail.type.Text1[UnityEngine.UI.Text].text = skilltype_list[info.skilltype]
    if skilltype_list[info.skilltargets] then 
        skilldetail.type.type2[CS.UGUISpriteSelector].index = info.skilltargets - 11
        skilldetail.type.Text2[UnityEngine.UI.Text].text = skilltype_list[info.skilltype]
        skilldetail.type.type2:SetActive(true)
        skilldetail.type.Text2:SetActive(true)
    else
        skilldetail.type.type2:SetActive(false)
        skilldetail.type.Text2:SetActive(false)
    end
    skilldetail.cd.Text[UnityEngine.UI.Text].text = ("冷却"..info.cd.."回合") --]]

    skilldetail.Text[UnityEngine.UI.Text].text = info.desc

    local flag_local_y = skilldetail.flag.transform.localPosition.y
    skilldetail.transform.position = Vector3(skilldetail.transform.position.x, click_pos.y - flag_local_y, 0)
    skilldetail.flag.transform.position = Vector3(click_pos.x, skilldetail.flag.transform.position.y, 0)
    skilldetail.flag.transform.localPosition = Vector3(skilldetail.flag.transform.localPosition.x, flag_local_y, 0)

    skilldetail:SetActive(true)
    skilldetail.transform:DOScale(Vector3.one, animate_time)
end

function roleinfo_details:UpdateOtherDetails(click_pos, info)
    if info.desc == "" then
        return
    end
    local otherdetail = self.view.otherdetail

    otherdetail.Text[UnityEngine.UI.Text].text = info.desc

    local algin_x = 0

    if click_pos.x < detail_width/2 + proofread then
        algin_x = x_while_left
    elseif (Screen_width - click_pos.x) < detail_width/2 + proofread then
        algin_x = x_while_right
    end

    local flag_local_y = otherdetail.flag.transform.localPosition.y

    if algin_x == 0 then
        otherdetail.transform.position = Vector3(click_pos.x, click_pos.y - flag_local_y * 2, 0)
        otherdetail.flag.transform.position = Vector3(click_pos.x, flag_local_y, 0)
        otherdetail.flag.transform.localPosition = Vector3(otherdetail.flag.transform.localPosition.x, flag_local_y, 0)
    else
        otherdetail.transform.position = Vector3(otherdetail.transform.position.x, click_pos.y - flag_local_y * 2, 0)
        otherdetail.transform.localPosition = Vector3(algin_x, otherdetail.transform.localPosition.y, 0)
        otherdetail.flag.transform.position = Vector3(click_pos.x, click_pos.y, 0)
        otherdetail.flag.transform.localPosition = Vector3(otherdetail.flag.transform.localPosition.x, flag_local_y, 0)
    end

    otherdetail:SetActive(true)
    otherdetail.transform:DOScale(Vector3.one, animate_time)
end

function roleinfo_details:PickBackSkillDetails()
    self.view.skilldetail.transform:DOScale(Vector3(1, 0.05, 1), animate_time):OnComplete(function() 
        self.view.skilldetail:SetActive(false)
    end)
end

function roleinfo_details:PickBackOtherDetails()
    self.view.otherdetail.transform:DOScale(Vector3(1, 0.05, 1), animate_time):OnComplete(function() 
        self.view.otherdetail:SetActive(false)
    end)
end

return roleinfo_details;
