class User
  require 'open-uri'

  def self.authenticate(username, password)
    base_url = APP_CONFIG['auth_url']
    base_url += '?' + {bar: username, pnr: password}.to_param
    auth_ok = false
    is_employee = false
    open(base_url) do |u| 
      result = u.read
      if result == "-1"
        return false
      end
      auth_ok = true if result[0] == "1"
      is_employee = true if result[1] == "1"
    end
    return false if !auth_ok
    {auth: auth_ok, employee: is_employee}
  end
end
