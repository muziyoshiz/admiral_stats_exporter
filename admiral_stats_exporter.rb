# Simple admiral stats exporter from kancolle-arcade.net
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

  # From 2016-07-26
  'Quest/info',

  # From 2016-10-27
  'Event/info',
  # イベントの開始・終了日とイベントアイコンの表示制御フラグのみを返す
  # 'Event/hold',
]

# Create new directory for latest JSON files
timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
json_dir = config['output']['dir'] + "/" + timestamp
FileUtils.mkdir_p(json_dir)

# Disable SSL verification for Windows support
conn = Faraday.new(url: BASE_URL, ssl: { verify: false }) do |faraday|
  faraday.request  :url_encoded
#  faraday.response :logger
  faraday.use      :cookie_jar
  faraday.adapter  Faraday.default_adapter
end

# Access to retrieve my session ID (JSESSIONID)
res = conn.get do |req|
  req.url TOP_URL
end

unless res.status == 200
  puts "ERROR: Failed to access #{BASE_URL}#{TOP_URL} (status code = #{res.status})"
  exit
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

unless res.status == 200
  puts "ERROR: Failed to login (status code = #{res.status})"
  exit
end

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
  filename = api_url.gsub('/', '_') + "_#{timestamp}.json"

  unless res.status == 200
    puts "ERROR: Failed to download #{filename} (status code = #{res.status})"
    next
  end

  File.write(json_dir + '/' + filename, res.body)
  puts "Succeeded to download #{filename}"
end
