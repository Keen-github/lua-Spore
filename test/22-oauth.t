#!/usr/bin/env lua

require 'Spore'

require 'Test.More'

if not pcall(require, 'OAuth') then
    skip_all 'no OAuth'
end

plan(7)

local response = { status = 200, headers = {} }
Spore.request = function (req)
    is(req.url, "http://services.org:9999/restapi/show?mocked_query")
    return response
end -- mock
Spore.Request.finalize = function (self)
    self.url = 'http://services.org:9999/restapi/show?dummy'
end -- mock
OAuth.Sign = function ()
    return nil, 'mocked_query'
end -- mock

if not require_ok 'Spore.Middleware.Auth.OAuth' then
    skip_rest "no Spore.Middleware.Auth.OAuth"
    os.exit()
end

local req = Spore.Request.new({ spore = { params = {} } })
type_ok( req, 'table', "Spore.Request.new" )
type_ok( req.headers, 'table' )

local r = Spore.Middleware.Auth.OAuth.call({}, req)
is( r, nil )

local data = {
        consumer_key    = 'xxx',
        consumer_secret = 'yyy',
        token           = '123',
        token_secret    = '456',
}
r = Spore.Middleware.Auth.OAuth.call(data, req)
is( r, nil )

req.env.spore.authentication = true
r = Spore.Middleware.Auth.OAuth.call(data, req)
is( r, response )