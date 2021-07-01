--------------------------------------------------------------------------------[[
-- Helpers

ESOPie = ESOPie or {}
ESOPie.utils = ESOPie.utils or {}

ESOPie.utils.GetActionTypeString = function(action)
    if type(action) == "number" and action > 0 then
        if action <= #ESOPie.actionNames then
            return ESOPie.actionNames[action]
        end
    end
    return nil
end

ESOPie.utils.FindEntryByID = function(id, haystack, ensureType)
    if id and haystack then
        for _, entry in pairs(haystack) do
            if entry.uniqueid == id and (ensureType == nil or entry.type == ensureType) then
                return entry
            end
        end
    end
    return nil
end

ESOPie.utils.FindEntryIndexByID = function(id, haystack, ensureType)
    if id and haystack then
        for i, entry in pairs(haystack) do
            if entry.uniqueid == id and (ensureType == nil or entry.type == ensureType) then
                return i
            end
        end
    end
    return nil
end

ESOPie.utils.NumericTableContains = function(table, search)
    for i, v in ipairs(table) do
        if v == search then return true end
    end
    return false
end

ESOPie.utils.TableContainsKey = function(table, search)
    return table[search] ~= nil
end

ESOPie.utils.EntryIsRing = function(entry)
    if not entry then return false end
    return entry.type == ESOPie.EntryType.Ring
end

ESOPie.utils.EntryIsSlot = function(entry)
    if not entry then return false end
    return entry.type == ESOPie.EntryType.Slot
end

ESOPie.utils.IsSubringAction = function(entry)
    if not ESOPie.utils.EntryIsSlot(entry) then return false end
    return entry.action == ESOPie.Action.Submenu
end

ESOPie.utils.IsCommandAction = function(entry)
    if not ESOPie.utils.EntryIsSlot(entry) then return false end
    return entry.action == ESOPie.Action.ChatExec or entry.action == ESOPie.Action.CodeExec
end

ESOPie.utils.IsCollectableAction = function(entry)
    if not ESOPie.utils.EntryIsSlot(entry) then return false end
    if      entry.action == ESOPie.Action.PlayEmote     then return true
    elseif  entry.action == ESOPie.Action.PlayMomento   then return true
    elseif  entry.action == ESOPie.Action.SummonAlly    then return true
    elseif  entry.action == ESOPie.Action.SetMount      then return true
    elseif  entry.action == ESOPie.Action.SetVanityPet  then return true
    elseif  entry.action == ESOPie.Action.SetCostume    then return true
    elseif  entry.action == ESOPie.Action.SetPolymorph  then return true
    end
end

ESOPie.utils.CollectionHasCategory = function(entry)
    if not ESOPie.utils.EntryIsSlot(entry) then return false end
    if      entry.action == ESOPie.Action.PlayEmote     then return true
    elseif  entry.action == ESOPie.Action.SummonAlly    then return true
    elseif  entry.action == ESOPie.Action.SetMount      then return true
    elseif  entry.action == ESOPie.Action.SetVanityPet  then return true
    --elseif  entry.action == ESOPie.Action.SetCostume    then return true
    --elseif  entry.action == ESOPie.Action.SetPolymorph  then return true
    end
    return false
end