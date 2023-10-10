require "sinatra"
require "json"
# auto-reload
require "sinatra/reloader"

require_relative "parser"

set :views, File.join(settings.root, "views")

get "/" do
    @greeting = "Pascal in Ruby"
    erb :index
end

post "/update" do
    content_type :json
    # parse
    request_body = JSON.parse(request.body.read)
    # process
    ast = parse(request_body["input"])
    # return
    { message: "ok", data: ast.to_json }.to_json
end