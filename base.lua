Wrk = require "wrk"
Date = os.date("%Y-%m-%d-%H-%M-%S")
ErrorLogFile = io.open("wrk-error-" .. Date .. ".log", "w")

if not ErrorLogFile then
    print("Error: Unable to open error.log")
    os.exit(1)
end

local function buildQueryString(params)
    local queryParts = {}
    for key, value in pairs(params) do
        table.insert(queryParts, key .. "=" .. tostring(value))
    end
    return table.concat(queryParts, "&")
end

function ReadCookies()
    local file = io.open("cookies.txt", "r")
    local cookies = ""
    if file then
        cookies = file:read("*all")
        cookies = cookies:gsub("\n$", "")
        file:close()
    else
        print("cookies.txt not found")
        os.exit()
    end

    return cookies
end

function CreateTestConfig(options)
    local config = {
        path = "/",
        method = "GET",
        params = {},
        headers = {},
        body = nil,
        logErrors = true,
        customTransformations = {},
    }

    for key, value in pairs(options) do
        config[key] = value
    end

    return config
end

function RunTest(config)
    local counter = 1
    local threads = {}

    if config.customTransformations and type(config.customTransformations) == "table" then
        for _, transformation in ipairs(config.customTransformations) do
            if type(transformation.func) == "function" then
                local result = transformation.func()
                if transformation.target == "headers" and type(result) == "table" then
                    for header, value in pairs(result) do
                        config.headers[header] = value
                    end
                elseif transformation.target == "body" and type(result) == "string" then
                    config.body = result
                elseif transformation.target == "query" and type(result) == "table" then
                    for param, value in pairs(result) do
                        config.params[param] = value
                    end
                end
            end
        end
    end

    Wrk.method = config.method

    for key, value in pairs(config.headers) do
        Wrk.headers[key] = value
    end

    if config.params then
        config.path = config.path .. "?" .. buildQueryString(config.params)
    end

    Wrk.path = config.path

    ---@diagnostic disable-next-line: lowercase-global
    request = function()
        Requests = Requests + 1
        if config.body then
            return Wrk.format(config.method, config.path, config.headers, config.body)
        else
            return Wrk.format(config.method, config.path, config.headers)
        end
    end


    ---@diagnostic disable-next-line: lowercase-global
    setup = function(thread)
        thread:set("id", counter)
        table.insert(threads, thread)
        counter = counter + 1
    end

    ---@diagnostic disable-next-line: lowercase-global
    init = function(_)
        Requests  = 0
        Responses = 0
    end

    ---@diagnostic disable-next-line: lowercase-global
    response = function(status, _headers, body)
        if status == nil then
            ErrorLogFile:write("Socket error or timeout\n" ..
                "\n---------------------------------------------------\n")
        else
            Responses = Responses + 1
            if config.logErrors and status ~= 200 then
                ErrorLogFile:write(string.format(
                    "Status: %d, Body: %s\n---------------------------------------------------\n", status, body))
            end
        end
    end

    ---@diagnostic disable-next-line: lowercase-global
    done = function(summary, latency, _requests)
        local summaryFileName = "wrk-summary-" .. Date .. ".log"
        local summaryFile = io.open(summaryFileName, "w")

        if not summaryFile then
            print("Error: Unable to open " .. summaryFileName)
            return
        end

        summaryFile:write("========== Performance Test Summary ==========\n\n")

        summaryFile:write("Latency Percentiles:\n")
        summaryFile:write(string.format("%-10s | %-15s\n", "Percentile", "Latency (ms)"))
        summaryFile:write(string.rep('-', 28) .. '\n')
        for _, p in pairs({ 50, 75, 90, 95, 99, 99.999 }) do
            local n = latency:percentile(p)
            summaryFile:write(string.format("%-10f%% | %-15.6f\n", p, n))
        end
        summaryFile:write("\n")

        local totalRequests = 0
        local totalResponses = 0
        for _, thread in ipairs(threads) do
            totalRequests = totalRequests + thread:get("Requests")
            totalResponses = totalResponses + thread:get("Responses")
        end

        summaryFile:write("Test Summary:\n")
        summaryFile:write(string.format("%-15s: %ds\n", "Test Duration", summary.duration / 1e6)) -- Convert from microseconds to seconds
        summaryFile:write(string.format("%-15s: %d\n", "Total Requests", totalRequests))
        summaryFile:write(string.format("%-15s: %d\n", "Total Responses", totalResponses))
        summaryFile:write(string.format("%-15s: %d\n", "Total Errors",
            summary.errors.connect + summary.errors.read + summary.errors.write + summary.errors.status +
            summary.errors.timeout))
        summaryFile:write("\n")

        summaryFile:write("Individual Thread Statistics:\n")
        for _, thread in ipairs(threads) do
            local threadId        = thread:get("id")
            local threadRequests  = thread:get("Requests")
            local threadResponses = thread:get("Responses")
            summaryFile:write(string.format("Thread %-4d: Made %-10d requests and got %-10d responses\n", threadId,
                threadRequests,
                threadResponses))
        end

        summaryFile:write("\n========== End of Test Summary ==========\n")

        summaryFile:close()
        ErrorLogFile:close()
    end
end
