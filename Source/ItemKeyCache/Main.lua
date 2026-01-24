--/run POINT_BLANK_SNIPER_ITEM_CACHE.orderedKeys.timestamp = 0
function PointBlankSniper.ItemKeyCache.ClearCache()
  POINT_BLANK_SNIPER_ITEM_CACHE = {
    version = 4,
    orderedKeys = nil, -- Serialized, this format
    --{
    --  itemKeyStrings = {},
    --  names = {},
    --},
    updateInProgress = false,
    newKeys = {
      itemKeyStrings = {},
      names = {},
    },
  }
end

PointBlankSniper.ItemKeyCache.CleanGetItemKeyInfo = Auctionator.AH.GetItemKeyInfo
function PointBlankSniper.ItemKeyCache.SetupHooks()
  hooksecurefunc(Auctionator.AH, "GetItemKeyInfo", function(itemKey, callback)
    local cache = PointBlankSniper.ItemKeyCache.State.keysSeen
    local allNames = PointBlankSniper.ItemKeyCache.State.orderedKeys.names
    local allKeyStrings = PointBlankSniper.ItemKeyCache.State.orderedKeys.itemKeyStrings

    itemKey = PointBlankSniper.Utilities.CleanItemKey(itemKey)

    local keyString = Auctionator.Utilities.ItemKeyString(itemKey)
    if POINT_BLANK_SNIPER_ITEM_CACHE.updateInProgress or PointBlankSniper.ItemKeyCache.State.NotYetLoaded or cache[keyString] ~= nil then
      return
    end

    PointBlankSniper.ItemKeyCache.CleanGetItemKeyInfo(itemKey, function(itemKeyInfo)
      if cache[keyString] == nil then
        local name = PointBlankSniper.Utilities.CleanSearchString(itemKeyInfo.itemName)
        local index = PointBlankSniper.Utilities.GetStartingIndex(1, #allNames, allNames, name)
        if allNames[index] == name then
          table.insert(allKeyStrings[index], keyString)
        end
        cache[keyString] = true
        table.insert(PointBlankSniper.ItemKeyCache.State.newKeys.itemKeyStrings, keyString)
        table.insert(PointBlankSniper.ItemKeyCache.State.newKeys.names, itemKeyInfo.itemName)
        if #PointBlankSniper.ItemKeyCache.State.newKeys.itemKeyStrings > PointBlankSniper.Constants.KeysThreshold then
          PointBlankSniper.ItemKeyCache.MergeKeys()
        end
      end
    end)
  end)
end

function PointBlankSniper.ItemKeyCache.AddItemID(itemID, altItemLevel)
  if not PointBlankSniper.ItemKeyCache.State.newKeys then
    PointBlankSniper.Utilities.Message("Auction House tab with keys scanning not opened yet")
    return
  end
  Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
    local itemName, itemLink, _, itemLevel = C_Item.GetItemInfo(itemID)
    itemLevel = altItemLevel or itemLevel
    local keyString = itemID .. " 0 " .. itemLevel .. " 0"
    table.insert(PointBlankSniper.ItemKeyCache.State.newKeys.itemKeyStrings, keyString)
    table.insert(PointBlankSniper.ItemKeyCache.State.newKeys.names, itemName)
    PointBlankSniper.Utilities.Message("Queued [" .. itemName .. "], [" .. keyString .. "]")
  end)
end

SlashCommandUtil.CheckAddSlashCommand("PBSID", SLASH_COMMAND_CATEGORY.ADDON, function(text)
  local id, itemLevel = strsplit(' ', text)
  local id = tonumber(id)
  local itemLevel = itemLevel and tonumber(itemLevel)
  if not id or id <= 0 or itemLevel and itemLevel <= 0 then
    PointBlankSniper.Utilities.Message("Invalid input")
  end

  PointBlankSniper.ItemKeyCache.AddItemID(id, itemLevel)
end)
SLASH_PBSID1 = "/pbsid"
