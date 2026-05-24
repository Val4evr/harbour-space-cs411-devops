require 'sinatra'
require 'json'

# Same JSON contract as the Go service (app/main.go): {"Name","Description","Url"}.
# Defaults to :4444 like the Go app; honour PORT so it can be test-run on another
# port without colliding with the native binary that the verify_run check needs.
set :server, 'webrick'
set :bind, '0.0.0.0'
set :port, (ENV['PORT'] || 4444).to_i

get '/' do
  content_type :json
  { Name: 'Hello', Description: 'World', Url: request.host }.to_json + "\n"
end
