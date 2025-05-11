require "base"

local doc_store_get = CreateTestConfig({
    path = "operation",
    params = { fileName = "param1", },
    headers = {
--      additional headers go here
    },
    log_errors = true
})

RunTest(doc_store_get)
