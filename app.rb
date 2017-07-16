require 'sinatra/base'

module Waitingroom
  class Application < Sinatra::Application
    get '/' do
      erb :index
    end

    get '/status' do
      erb :status, locals: {
        train: {
          destination: params[:destination],
          id: params[:id],
          time: '',
          track: ''
        }
      }
    end
  end
end
