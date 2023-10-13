require "sinatra"
require "json"
# auto-reload
require "sinatra/reloader"

require_relative "parser"
require_relative "interpreter"

set :views, File.join(settings.root, "views")

get "/" do
    @title = "Pascal in Ruby"
    erb :index
end

post "/update" do
    content_type :json
    request_body = JSON.parse(request.body.read)
    # globals
    $symbols = Hash.new
    $identifiers = Array.new
    $issues = Array.new
    # parse
    characters, tokens, ast = parse(request_body["input"])
    # interpret
    output = interpret(ast)
    # return json
    {
        message: "ok",
        characters: characters,
        tokens: tokens.to_json,
        ast: ast.to_json,
        symbols: $symbols.to_json,
        identifiers: $identifiers.to_json,
        issues: $issues.to_json,
        output: output
    }.to_json
end