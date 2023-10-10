require "sinatra"
require "json"
# auto-reload
require "sinatra/reloader"

set :views, File.join(settings.root, "views")

get "/" do
    @greeting = "hello sinatra"
    erb :index
end

post "/update" do
    content_type :json
    # parse
    request_body = JSON.parse(request.body.read)
    # process
    data = request_body
    # return
    { message: "ok", data: data["input"] }.to_json
end