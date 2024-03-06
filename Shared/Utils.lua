function PrintTable(table, nb)
    if nb == nil then
        nb = 0
    end

    if type(table) == 'table' then
        local s = ''
        for i = 1, nb + 1, 1 do
            s = s .. "    "
        end
    
        s = '{\n'
        for k,v in pairs(table) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            for i = 1, nb, 1 do
                s = s .. "    "
            end
            s = s .. '['..k..'] = ' .. PrintTable(v, nb + 1) .. ',\n'
        end
    
        for i = 1, nb, 1 do
            s = s .. "    "
        end
    
        return s .. '}'
    else
        return tostring(table)
    end
end

-- Check XP is an integer
function IsInt(xp)
    xp = tonumber(xp)
    if xp and xp == math.floor(xp) then
        return true
    end
    return false
end

-- print Errer
function PrintError(message)
    local out = string.format('^1Error: ^5%s',  message)
    local s = string.rep("=", string.len(out))
    print('^1' .. s)
    print(out)
    print('^1' .. s .. '^7')  

    Client.SendChatMessage(message)
end