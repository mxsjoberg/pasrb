require "sinatra"
require "json"
# auto-reload
require "sinatra/reloader"

require_relative "parser"
require_relative "interpreter"

set :views, File.join(settings.root, "views")

get "/" do
    @greeting = "Pascal in Ruby"
    erb :index
end

post "/update" do
    content_type :json
    request_body = JSON.parse(request.body.read)
    # parse
    characters, tokens, ast, issues = parse(request_body["input"])
    # interpret
    result = interpret(ast)
    # return json
    { message: "ok", characters: characters, tokens: tokens.to_json, ast: ast.to_json, issues: issues.to_json, result: result }.to_json
end