# Simple admiral stats exporter from kancolle-arcade.net
require 'faraday'
require 'faraday-cookie_jar'
require 'yaml'
require 'json'

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

  # From 2017-02-14
  'RoomItemList/info'
]

# Prefix for memo file name
MEMO_FILE_PREFIX = 'memo'

# Admiral Stats Import URL
AS_IMPORT_URL = 'https://www.admiral-stats.com/api/v1/import'
# User Agent for logging on www.admiral-stats.com
AS_HTTP_HEADER_UA = 'AdmiralStatsExporter-Ruby/1.6.3'

# Check whether to upload JSON files or not
do_upload = ARGV.include?('--upload')
if do_upload and config['upload']['token'].to_s.empty?
  puts 'ERROR: For upload, authorization token is required in config.yaml'
  exit 1
end

# Check whether to output a memo file or not
memo = nil
if ARGV.include?('--memo')
  print 'Memo: '
  memo = STDIN.gets
end

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
  exit 1
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
  exit 1
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

# Create memo file
if memo
  memo_filename = "#{MEMO_FILE_PREFIX}_#{timestamp}.txt"
  File.write(json_dir + '/' + memo_filename, memo)
  puts "Succeeded to create #{memo_filename}"
end

# Upload exported files to Admiral Stats
if do_upload
  # New connection for Admiral Stats API
  as_conn = Faraday.new do |faraday|
    faraday.request  :url_encoded
#  faraday.response :logger
    faraday.adapter  Faraday.default_adapter
  end

  # Set Authorization header
  as_conn.authorization :Bearer, config['upload']['token']

  # Get currently importable file types
  res = as_conn.get do |req|
    req.url "#{AS_IMPORT_URL}/file_types"
    req.headers['User-Agent'] = AS_HTTP_HEADER_UA
  end

  case res.status
    when 200
      importable_file_types = JSON.parse(res.body)
      puts "Importable file types: #{importable_file_types.join(', ')}"
    when 401
      json = JSON.parse(res.body)
      json['errors'].each do |error|
        puts "ERROR: #{error['message']}"
      end
      exit 1
  end

  Dir::foreach(json_dir) do |f|
    if f =~ /^(.+)_(\d{8}_\d{6})\.json$/
      file_type, timestamp = $1, $2
      next unless importable_file_types.include?(file_type)

      # Open, read and close file
      json = open(File.join(json_dir, f), &:read)

      res = as_conn.post do |req|
        req.url "#{AS_IMPORT_URL}/#{file_type}/#{timestamp}"
        req.headers['Content-Type'] = 'application/json'
        req.headers['User-Agent'] = AS_HTTP_HEADER_UA
        req.body = json
      end

      case res.status
        when 200, 201
          json = JSON.parse(res.body)
          puts "#{json['data']['message']}（ファイル名：#{f}）"
        when 400, 401
          json = JSON.parse(res.body)
          json['errors'].each do |error|
            puts "ERROR: #{error['message']}（ファイル名：#{f}）"
          end
        else
          # Unexpected error
          puts "ERROR: #{res.body}"
      end
    end
  end
end
