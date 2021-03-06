require 'httparty'
require 'json'
require_relative "dashboard-api/version"
require 'organizations'
require 'networks'
require 'admins'
require 'devices'
require 'templates'
require 'clients'
require 'phones'
require 'ssids'
require 'sm'
require 'vlans'
require 'switchports'
require 'saml'

# Ruby Implementation of the Meraki Dashboard api
# @author Joe Letizia
class DashboardAPI
  include HTTParty
  include Organizations
  include DashboardAPIVersion
  include Networks
  include Clients
  include Devices
  include SM
  include SSIDs
  include Admins
  include Switchports
  include VLANs
  include Phones
  include Templates
  include SAML
  base_uri "https://dashboard.meraki.com/api/v0"

  attr_reader :key

  def initialize(key)
    @key = key
  end

  # @private
  # Inner function, not to be called directly
  # @todo Eventually this will need to support POST, PUT and DELETE. It also
  #   needs to be a bit more resillient, instead of relying on HTTParty for exception
  #   handling
  def make_api_call(endpoint_url, http_method, options_hash={})
    headers = {"X-Cisco-Meraki-API-Key" => @key, 'Content-Type' => 'application/json'}

    options = {:headers => headers, :body => options_hash.to_json}
    case http_method
    when 'GET'
      res = HTTParty.get("#{self.class.base_uri}/#{endpoint_url}", options)
      raise "404 returned. Are you sure you are using the proper IDs?" if res.code == 404
      raise "Bad request due to the following error(s): #{JSON.parse(res.body)['errors']}" if res.body.include?('errors')
      return JSON.parse(res.body)
    when 'POST'
      res = HTTParty.post("#{self.class.base_uri}/#{endpoint_url}", options)
      raise "Bad Request due to the following error(s): #{res['errors']}" if res['errors']
      raise "404 returned. Are you sure you are using the proper IDs?" if res.code == 404
      begin
        return JSON.parse(res.body)
      rescue JSON::ParserError => e
        return res.code
      rescue TypeError => e
        return res.code
      end
    when 'PUT'
      res = HTTParty.put("#{self.class.base_uri}/#{endpoint_url}", options)
      # needs to check for is an array, because when you update a 3rd party VPN peer, it returns as an array
      # if you screw something up, it returns as a Hash, and will hit the normal if res['errors'
      (raise "Bad Request due to the following error(s): #{res['errors']}" if res['errors']) unless JSON.parse(res.body).is_a? Array
      raise "404 returned. Are you sure you are using the proper IDs?" if res.code == 404
      return JSON.parse(res.body)
    when 'DELETE'
      res = HTTParty.delete("#{self.class.base_uri}/#{endpoint_url}", options)
      raise "Bad Request due to the following error(s): #{res['errors']}" if res['errors']
      raise "404 returned. Are you sure you are using the proper IDs?" if res.code == 404
      return res
    else
      raise 'Invalid HTTP Method. Only GET, POST, PUT and DELETE are supported.'
    end
  end
end
