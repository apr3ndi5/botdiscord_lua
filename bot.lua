local discordia = require("discordia")
local json = require("json")
local timer = require("timer")
local coro = require("coro-http")
local client = discordia.Client()

local wait = {} -- {id = memberid, cmd = "payday", 120}

local commands = {
    {Command = "ping", Description = "Sends message pong."};
    {Command = "chucknorris", Description = "Sends a Chuck Norris joke."};
    {Command = "cool", Description = "Sends a percentage of how cool someone is."}
}

function ChuckNorris(message)
    coroutine.wrap(function()
        local link = "https://api.chucknorris.io/jokes/random"
        local result, body = coro.request("GET", link)
        body = json.parse(body)
        --message:reply("<@!"..message.member.id.."> "..body["value"])
        message:reply{
            embed = {
                title = "Here's a joke!";
                fields = {
                    {name = "Chuck Norris"; value = body["value"]; inline = false};
                };
                color = discordia.Color.fromRGB(100,100,255).value;
            };
        }
    end)()
end

function IsCooldown(id, c)
    for i,v in pairs(wait) do
        if type(v) == "table" then
            if v.memberid == id then
                if v.cmd == c then
                    return true, v
                end
            end
        end
    end
    return false
end

client:on("messageCreate", function(message)
    local content = message.content
    local member = message.member
    local memberid = message.member.id
    
    if content:lower() == "!ping" then
        message:reply("pong")
    end

    if content:lower() == "!chucknorris" then
        ChuckNorris(message)
    end

    if content:lower():sub(1,#"!cool") == "!cool" then
        local mentioned = message.mentionedUsers
        if #mentioned == 1 then
            local member = message.guild:getMember(mentioned[1][1])
            message:reply{
                embed = {
                    fields = {
                        {name = "Coolness Detected"; value = member.username.." has "..math.random(1,100).."% coolness!"}
                    };
                    color = discordia.Color.fromRGB(100,100,255).value;
                };
            }
        elseif #mentioned == 0 then
            message:reply{
                embed = {
                    fields = {
                        {name = "Coolness Detected"; value = message.member.username.." has "..math.random(1,100).."% coolness!"}
                    };
                    color = discordia.Color.fromRGB(100,100,255).value;
                };
            }
        end
    end

    if content:lower():sub(1,#"!payday") == "!payday" then
        local isCool, Table = IsCooldown(memberid, "payday")
        if isCool == false then
            local open = io.open("eco.json", "r")
            local parse = json.parse(open:read())
            local earned = math.random(5,10)
            table.insert(wait, {memberid = member.id, cmd = "payday", time = 30})
            open:close()
            if parse[memberid] then
                parse[memberid] = parse[memberid] + earned
            else
                parse[memberid] = earned
            end
            message:reply("<@!"..memberid.."> has earned $"..earned.."!")
            open = io.open("eco.json", "w")
            open:write(json.stringify(parse))
            open:close()
        elseif Table ~= nil then
            message:reply("<@!"..memberid.."> sorry but you still have to wait "..Table.time.." seconds left!")
        end
    end

    if content:lower():sub(1,#"!bal") == "!bal" then
        local open = io.open("eco.json", "r")
        local parse = json.parse(open:read())
        open:close()
        message:reply("<@!"..memberid.."> has $"..(parse[memberid] or 0))
    end

    if content:lower():sub(1,#"!cmd") == "!cmd" then
        local list = "```"
        for i,v in pairs(commands) do
            list = list..v.Command..": "..v.Description.."\n"
        end
        list = list.."```"
        message:reply(list)
    end
    
    if content:lower() == "!reboot" then
        if memberid == "140482658873376768" then
            message:reply("Rebooting...")
            client:stop()
        end
    end

end)

timer.setInterval(1000, function()
    for i,v in pairs(wait) do
        if type(v) == "table" then
            if v.time > 0 then
                wait[i].time = wait[i].time - 1
            else
                wait[i] = nil
            end
        end
    end
end)

client:run('Bot NTEyNDQxNDg4MjY1OTY5Njk2.Ds5qFg.01wx3zfy7O5ORbZi45oMuktyTho')