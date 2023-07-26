local function files(configs)
    --- @param query string
    --- @param fullscren boolean|integer
    --- @param options Option
    local function impl(query, fullscren, options)
        local source = options.unrestrict and configs.files.command.unrestricted
            or configs.files.command.restricted
    end

    return impl
end
