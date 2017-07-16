require 'sinatra/base'

module Waitingroom
  class Application < Sinatra::Application
    get '/' do
      'hi'
    end
  end
end
