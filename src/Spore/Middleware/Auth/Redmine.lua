local basicAuth = require 'Spore.Middleware.Auth.Basic'

_ENV = nil
local m = {}

function m:call (req)
  -- Uses basic HTTP authentication by passing API Key as username  with random password
  local data = { username = self.api_key, password = 'PasswordNotNeeded' }
  basicAuth.call(data, req)
end

return m
