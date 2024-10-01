---App settings
local FONT_SIZE = 12
local FONT_SPACE = 9

---End app settings

local globalFrame = CreateFrame("Frame")
local bagFrame = CreateFrame("Frame")

---@type Frame
local mainFrame = _G["SomeName"]

local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 3, -4)
scrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)

local scrollChild = CreateFrame("Frame")
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetWidth(mainFrame:GetWidth() - 18)
scrollChild:SetHeight(1) 

ResizeButton = {}

function ResizeButton:OnMouseDown(self)
    self:GetParent():StartSizing("BOTTOMRIGHT")
end

function ResizeButton:OnMouseUp(self)
    self:GetParent():StopMovingOrSizing("BOTTOMRIGHT")
end

--- @alias ItemData { itemFrame: Frame, iconFrame: Texture, itemName: FontString, changing: boolean, itemStackInput: EditBox, itemStack: FontString }

--- @type { [integer]: ItemData }
local frameCache = {}

--- @type number
local frameIndex = 0

---Refresh the item stack input size of a specific frame
---@param frame ItemData
function RefreshItemStackInput(frame)
    local stackCount = GetStackCount(frame.itemName:GetText())
    frame.itemStack:SetText(stackCount.." /")
    local width = frame.itemStack:GetStringWidth()

    frame.itemStackInput:SetPoint("LEFT", frame.itemStack, width - string.len(stackCount - 1) * 2, 0)
end

---Set the frame to the desired data
---@param frame ItemData
---@param itemName string
---@param itemTexture string|integer
---@param predefinedItemStack integer?
function SetFrameData(frame, itemName, itemTexture, predefinedItemStack)
    frame.iconFrame:SetTexture(itemTexture)
    frame.itemName:SetText(itemName)

    RefreshItemStackInput(frame)
    
    if predefinedItemStack then
        frame.itemStackInput:SetNumber(predefinedItemStack)
    else
        frame.itemStackInput:SetText("")
    end
end

---Check if a item is already in the list
---@param itemName string
---@return boolean
function CheckForItem(itemName)
    for _, data in pairs(frameCache) do
        if data.itemName:GetText() == itemName then
            return true
        end
    end

    return false
end

---Create or get a item frame from the frame cache
---@return ItemData
function CreateOrGetItemFrame()
    frameIndex = frameIndex + 1
    local index = frameIndex
      
    if frameCache[index] == nil then
        frameCache[index] = {}
        
        -- Creating every component for the frame
        frameCache[index].itemFrame = CreateFrame("Frame", "Item", scrollChild)
        frameCache[index].iconFrame = frameCache[index].itemFrame:CreateTexture()
        frameCache[index].itemName = frameCache[index].itemFrame:CreateFontString()
        frameCache[index].itemStackInput = CreateFrame("EditBox", "Item stack input")
        frameCache[index].itemStack = frameCache[index].itemFrame:CreateFontString()
        frameCache[index].changing = false

        -- Defining every settings of all components
        -- Frame settings
        --- @type Frame
        local frame = frameCache[index].itemFrame

        frame:SetPoint("TOPLEFT", 6, (index - 1) * -40)
        frame:SetSize(350 - 32, 40)

        -- End frame settings

        --- Item stack settings
        local itemStack = frameCache[index].itemStack

        itemStack:SetSize(0, 14)
        itemStack:SetFont("fonts/arialn.ttf", FONT_SIZE + 3, "")
        itemStack:SetPoint("LEFT", 40, -FONT_SPACE + 3)
        --- End item stack settings

        --- Item stack settings
        local itemStackInput = frameCache[index].itemStackInput
        
        itemStackInput:SetAutoFocus(false)
        itemStackInput:SetSize(150, 14)
        itemStackInput:SetFont("fonts/arialn.ttf", FONT_SIZE, "")
        itemStackInput:SetNumeric(true)
        itemStackInput:SetFrameLevel(2)

        itemStackInput:SetScript("OnKeyDown", function (self, key)
            if key == "ESCAPE" then
                itemStackInput:ClearFocus()
            end
        end)
        --- End item stack settings

        -- Icon settings
        --- @type Texture
        local itemIconFrame = frameCache[index].iconFrame

        itemIconFrame:SetSize(32, 32)
        itemIconFrame:SetPoint("LEFT", frame)
    
        -- End icon settings
        -- Item name text settings
        --- @type FontString
        local txt = frameCache[index].itemName

        txt:SetFont("fonts/arialn.ttf", FONT_SIZE - 1)
        txt:SetText("unknow")
        txt:SetPoint("LEFT", 40, FONT_SPACE)
        -- End item name text settings
        
        -- Button settings
        --- @type Button
        local btn = CreateFrame("Button", "item"..tostring(index), frame)
    
        btn:SetSize(24, 24)
        btn:SetPoint("RIGHT", frame, -12)
        
        btn:SetScript("OnClick", function ()
            frame:Hide()
            frameCache[index].changing = true

            --- @type { [integer]: ItemData }
            local dataCache = {}
            local dataIndex = 1

            for index, data in ipairs(frameCache) do
                if not data.changing then
                    table.insert(dataCache, dataIndex, data)
                    dataIndex = dataIndex + 1
                end
            end

            frameCache[index].changing = false

            for index, data in ipairs(dataCache) do
                local texture = data.iconFrame:GetTexture()

                if texture then
                    local numberToParse = nil

                    if data.itemStackInput:GetText() ~= "" then
                        numberToParse = data.itemStackInput:GetNumber()
                    end

                    SetFrameData(frameCache[index], data.itemName:GetText(), texture, numberToParse)
                end
            end

            frame:Show()

            local lastItemFrame = frameCache[frameIndex].itemFrame
            lastItemFrame:Hide()

            local lastItemStackInput = frameCache[frameIndex].itemStackInput
            lastItemStackInput:SetText("")
            lastItemStackInput:ClearFocus()
            lastItemStackInput:Hide()

            frameIndex = frameIndex - 1
        end)

        -- End button settings
        
        -- Texture button settings
        ---@type Texture
        local closeButton = btn:CreateTexture()
        
        closeButton:SetTexture("Interface/Buttons/CancelButton-Up")
        closeButton:SetSize(24, 24)
        closeButton:SetPoint("TOPLEFT")
        -- End texture button settings
    end

    return frameCache[frameIndex]
end

---comment
---@param search string item to search 
---@return { [integer]: ContainerItemInfo }
function GetContainerItem(search)
    local itemFind = {}

    for bag = 0,5 do
        for slot = 1,C_Container.GetContainerNumSlots(bag) do
            local item = C_Container.GetContainerItemLink(bag, slot)
            if item then
                local itemName = C_Item.GetItemInfo(item)

                if itemName == search then
                    tinsert(itemFind, C_Container.GetContainerItemInfo(bag, slot))
                end
            end
        end
    end

    return itemFind
end

---Get the inventory stack count for a item
---@param itemName string
---@return integer
function GetStackCount(itemName)
    local containerItem = GetContainerItem(itemName)
    local stackCount = GetTotalStackCountFromContainerItem(containerItem)

    return stackCount
end

local ItemClassEnum = {
    Consumable = 0,
    Container = 1,
    Weapon = 2,
    Gem	= 3,
    Armor =	4,	
    Reagent = 5,
    Projectile = 6,
    Tradegoods = 7,
    ItemEnhancement = 8,		
    Recipe = 9,
    CurrencyTokenObsolete = 10,
    Quiver = 11,
    Questitem = 12,	
    Key = 13,
    PermanentObsolete = 14,
    Miscellaneous = 15,
    Glyph = 16,
    Battlepet = 17,
    WoWToken = 18,
    Profession = 19,
}

---Check if the item is a valid item (eg: not a recipe)
---@param classId number The class id of the item
---@return boolean
function IsItemValid(classId)
    local itemValidity = 
        classId ~= ItemClassEnum.Container and 
        classId ~= ItemClassEnum.Recipe and
        classId ~= ItemClassEnum.Questitem and
        classId ~= ItemClassEnum.Battlepet and
        classId ~= ItemClassEnum.Miscellaneous

    if itemValidity then
        return true
    end

    return false
end

---Get the total stack count from a inventory (container) item
---@param containerItem { [integer]: ContainerItemInfo } The containers item
---@return integer stackCount total stack count
function GetTotalStackCountFromContainerItem(containerItem)
    local totalStackCount = 0

    for _, item in ipairs(containerItem) do
        totalStackCount = totalStackCount + item.stackCount
    end

    return totalStackCount
end

mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton");

mainFrame:SetScript("OnDragStart", function (self)
    mainFrame:StartMoving()
end)

mainFrame:SetScript("OnDragStop", function (self)
    mainFrame:StopMovingOrSizing()
    mainFrame:SetFrameLevel(0)
end)

globalFrame:RegisterEvent("GLOBAL_MOUSE_DOWN")
globalFrame:SetScript("OnEvent", function (self, event, button)
    local _, item = GameTooltip:GetItem()

    if item and IsControlKeyDown() and button == "RightButton" then
        local itemName, _, _, _, _, _, _, _, _, itemTexture, _, classId = C_Item.GetItemInfo(item)

        if not CheckForItem(itemName) and IsItemValid(classId) then
            local frame = CreateOrGetItemFrame()
            
            local itemFrame = frame.itemFrame
            local itemStackInput = frame.itemStackInput

            SetFrameData(frame, itemName, itemTexture)

            if not itemFrame:IsShown() then
                itemFrame:Show()
            end

            if not itemStackInput:IsShown() then
                itemStackInput:Show()
            end
        end
    end
end)

bagFrame:RegisterEvent("BAG_UPDATE")
bagFrame:SetScript("OnEvent", function (self, event, bagId)
    if bagId >= 0 and bagId <= 5 then
        for index, data in pairs(frameCache) do
            RefreshItemStackInput(data)
        end
    end
end)