require 'sinatra/base'

module Waitingroom
  class Application < Sinatra::Application
    get '/' do
      erb :index
    end
  end
end
