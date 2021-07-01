--------------------------------------------------------------------------------[[
-- Helpers

function GetActionTypeString(action)
    if type(action) == "number" and action > 0 then
        if action <= #ESOPie.actionNames then
            return ESOPie.actionNames[action]
        end
    end
    return nil
end

function FindEntryByID(id, haystack, ensureType)
    if id and haystack then
        for _, entry in pairs(haystack) do
            if entry.uniqueid == id and (ensureType == nil or entry.type == ensureType) then
                return entry
            end
        end
    end
    return nil
end

function FindEntryByName(name, haystack, ensureType)
    if name and haystack then
        for _, entry in pairs(haystack) do
            if entry.name == name and (ensureType == nil or entry.type == ensureType) then
                return entry
            end
        end
    end
    return nil
end

function FindEntryByIndex(index, haystack)
    if index and haystack then return haystack[index] end
    return nil
end

function FindEntryIndexByID(id, haystack, ensureType)
    if id and haystack then
        for i, entry in pairs(haystack) do
            if entry.uniqueid == id and (ensureType == nil or entry.type == ensureType) then
                return i
            end
        end
    end
    return nil
end


function FindEntryIndexByName(name, haystack)
    if name and haystack then
        for i, entry in pairs(haystack) do
            if entry.name == name then
                return i
            end
        end
    end
    return nil
end

function EntryIsRing(entry)
    if not entry then return false end
    return entry.type == ESOPie.EntryType.Ring
end

function EntryIsSlot(entry)
    if not entry then return false end
    return entry.type == ESOPie.EntryType.Slot
end

function IsSubringAction(entry)
    if not EntryIsSlot(entry) then return false end
    return entry.action == ESOPie.Action.Submenu
end

function IsCommandAction(entry)
    if not EntryIsSlot(entry) then return false end
    return entry.action == ESOPie.Action.ChatExec or entry.action == ESOPie.Action.CodeExec
end

function IsEmoteAction(entry)
    if not EntryIsSlot(entry) then return false end
    return entry.action == ESOPie.Action.PlayEmote
end

function IsAllyAction(entry)
    if not EntryIsSlot(entry) then return false end
    return entry.action == ESOPie.Action.SummonAlly
end

function IsCollectableAction(entry)
    if not EntryIsSlot(entry) then return false end
    if      entry.action == ESOPie.Action.PlayEmote     then return true
    elseif  entry.action == ESOPie.Action.PlayMomento   then return true
    elseif  entry.action == ESOPie.Action.SummonAlly    then return true
    elseif  entry.action == ESOPie.Action.SetMount      then return true
    elseif  entry.action == ESOPie.Action.SetVanityPet  then return true
    elseif  entry.action == ESOPie.Action.SetCostume    then return true
    elseif  entry.action == ESOPie.Action.SetPolymorph  then return true
    end
end

function CollectionHasCategory(entry)
    if not EntryIsSlot(entry) then return false end
    if      entry.action == ESOPie.Action.PlayEmote     then return true
    elseif  entry.action == ESOPie.Action.SummonAlly    then return true
    --elseif  entry.action == ESOPie.Action.SetMount      then return true
    --elseif  entry.action == ESOPie.Action.SetVanityPet  then return true
    elseif  entry.action == ESOPie.Action.SetCostume    then return true
    elseif  entry.action == ESOPie.Action.SetPolymorph  then return true
    end
    return false
end