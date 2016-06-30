# Simple admiral data exporter from kancolle-arcade.net
require 'faraday'
require 'faraday-cookie_jar'
require 'yaml'

# Read configurations
config = YAML.load_file('config.yaml')

# Base URL
BASE_URL = 'https://kancolle-arcade.net'

# Top page
TOP_URL = '/ac/'

# POST
LOGIN_URL = '/ac/api/Auth/login'

# Common part of API URLs
API_BASE_URL = '/ac/api/'

# Common HTTP headers
HTTP_HEADER_HOST = 'kancolle-arcade.net'
HTTP_HEADER_REFERER = 'https://kancolle-arcade.net/ac'
HTTP_HEADER_UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:45.0) Gecko/20100101 Firefox/45.0'

# API URLs
API_URLS = [
  'Personal/basicInfo',
  'Area/captureInfo',
  'TcBook/info',
  'EquipBook/info',
  'Campaign/history',
  'Campaign/info',
  'Campaign/present',

  # From REVISION 2 (2016-06-30)
  'CharacterList/info',
  'EquipList/info',
]

# Create new directory for latest JSON files
json_dir = config['output']['dir'] + "/" + Time.now.strftime('%Y%m%d_%H%M%S')
FileUtils.mkdir_p(json_dir)

conn = Faraday.new(:url => BASE_URL) do |faraday|
  faraday.request  :url_encoded
  faraday.response :logger
  faraday.use      :cookie_jar
  faraday.adapter  Faraday.default_adapter
end

# Access to retrieve my session ID (JSESSIONID)
res = conn.get do |req|
  req.url TOP_URL
end

# Login (POST)
res = conn.post do |req|
  req.url LOGIN_URL
  req.headers['Content-Type'] = 'application/json'
  req.headers['Host']       = HTTP_HEADER_HOST
  req.headers['Referer']    = HTTP_HEADER_REFERER
  req.headers['User-Agent'] = HTTP_HEADER_UA
  req.headers['X-Requested-With'] = 'XMLHttpRequest'
  req.body = "{\"id\":\"#{config['login']['id']}\",\"password\":\"#{config['login']['password']}\"}"
end

# TODO Check login result

# Access to APIs
API_URLS.each do |api_url|
  res = conn.get do |req|
    req.url API_BASE_URL + api_url
    req.headers['Host']       = HTTP_HEADER_HOST
    req.headers['Referer']    = HTTP_HEADER_REFERER
    req.headers['User-Agent'] = HTTP_HEADER_UA
    req.headers['X-Requested-With'] = 'XMLHttpRequest'
  end

  # Create filename from URL automatically
  filename = api_url.gsub('/', '_') + '.json'

  File.write(json_dir + '/' + filename, res.body)
end
