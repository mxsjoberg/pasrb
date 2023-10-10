require "sinatra"
# auto-reload
require "sinatra/reloader"

set :views, File.join(settings.root, "views")

get "/" do
    @greeting = "hello sinatra"
    erb :index
end