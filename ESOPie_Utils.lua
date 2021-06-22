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
