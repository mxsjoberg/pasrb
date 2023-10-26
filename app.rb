require "sinatra"
require "json"
# auto-reload
require "sinatra/reloader"

require_relative "parser"
require_relative "interpreter"

set :views, File.join(settings.root, "views")

get "/" do
    $input = Hash.new
    @title = "Pascal in Ruby"
    erb :index
end

post "/input" do
    content_type :json
    request_body = JSON.parse(request.body.read)
    $input[request_body["identifier"].to_sym] = request_body["text"]
    $output = Array.new
    # interpret
    $ast.each do |branch|
        interpret(branch)
    end
    # return json
    {
        message: "ok",
        symbols: $symbols.to_json,
        output: $output
    }.to_json
end

post "/update" do
    content_type :json
    request_body = JSON.parse(request.body.read)
    # globals
    $symbols = Hash.new
    $identifiers = Array.new
    $issues = Array.new
    $output = Array.new
    # input
    # $inputs = Array.new
    # parse
    $ast = nil
    characters, tokens, $ast = parse(request_body["text"])
    
    # TODO: create fresh temp_inputs and compare with input to remove identifiers no longer in program
    
    # interpret
    $ast.each do |branch|
        interpret(branch)
    end
    # return json
    {
        message: "ok",
        characters: characters,
        tokens: tokens.to_json,
        ast: $ast.to_json,
        symbols: $symbols.to_json,
        identifiers: $identifiers.to_json,
        input: $input.to_json,
        issues: $issues.to_json,
        output: $output
    }.to_json
end
