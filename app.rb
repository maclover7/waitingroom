require 'sinatra/base'
require 'rest-client'
require 'nokogiri'

module Waitingroom
  class Application < Sinatra::Application
    get '/' do
      erb :index
    end

    get '/status' do
      train = NJTApi.get_train(params[:id],
                               params[:origin_code],
                               params[:destination_code],
                               params[:destination_name]) || {}
      erb :status, locals: { train: train }
    end

    private

    def render_stop(stop)
      str = "#{stop[:name]}: #{stop[:time]}"

      if stop[:track]
        str << " @ Track #{stop[:track]}"
      end

      if stop[:status]
        str << " (#{stop[:status]})"
      end

      str
    end
  end

  class NJTApi
    def self.get_train(id, origin_code, destination_code, destination_name)
      res = RestClient.get(
        "http://traindata.njtransit.com:8092/NJTTrainData.asmx/getTrainScheduleXML",
        {
          'Host' => 'traindata.njtransit.com',
          'params' => {
            'username' => ENV['NJT_USERNAME'],
            'password'=> ENV['NJT_PASSWORD'],
            'station' => origin_code
          }
        }
      )

      trains = Nokogiri::XML.parse(res).xpath('//STATION//ITEMS//ITEM')
      serialized_train = { id: id, stops: [] }

      trains.each do |train|
        next unless train.xpath('TRAIN_ID').text == id

        serialized_train[:stops] << {
          name: origin_code,
          time: train.xpath('SCHED_DEP_DATE').text,
          track: train.xpath('TRACK').text,
          status: train.xpath('STATUS').text
        }

        train.xpath('STOPS//STOP').each do |stop|
          next unless stop.xpath('NAME').text == destination_name

          if origin_code == destination_code
            serialized_train[:stops][0][:time] = stop.xpath('TIME').text
          else
            serialized_train[:stops] << {
              name: destination_code,
              time: stop.xpath('TIME').text
            }
          end

          break
        end

        break
      end

      # Train may have left origin already
      if serialized_train[:stops].empty?
        # Check and see if it's on the destination's departure board
        serialized2 = get_train(id, destination_code, destination_code, destination_name)

        if serialized2[:stops].empty?
          # if not, then train has not started its journey yet
          serialized_train
        else
          # if so, then train has indeed left its origin
          serialized2
        end
      else
        serialized_train
      end
    end
  end
end
