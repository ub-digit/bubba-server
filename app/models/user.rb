class User
  require 'open-uri'

  def self.authenticate(username, password)
    base_url = APP_CONFIG['auth_url']
    base_url += '?' + {bar: username, pnr: password}.to_param
    url = URI.parse(base_url)
    auth_ok = false
    is_employee = false
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    https.ssl_version = :TLSv1
    req = https.request(Net::HTTP::Get.new(url.request_uri))
    result = req.body
    if result == "-1"
      return false
    end
    auth_ok = true if result[0] == "1"
    is_employee = true if result[1] == "1"
    return false if !auth_ok
    {auth: auth_ok, employee: is_employee}
  end
end
