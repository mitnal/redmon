module Redmon
  class App < Sinatra::Base

    configure :development do
      require "sinatra/reloader"
      register Sinatra::Reloader
    end

    helpers Redmon::Helpers

    get '/' do
      @redis_url = redis_url
      @redises = Redmon[:redis_urls].map { |url| redis(url) }
      @config = redis(redis_url).config
      haml :app
    end

    get '/cli' do
      args = params[:command].split
      @cmd = args.shift.downcase.intern
      begin
        raise RuntimeError unless redis(redis_url).supported? @cmd
        @result = redis(redis_url).redis.send @cmd, *args
        @result = redis(redis_url).empty_result if @result == []
        haml :cli
      rescue ArgumentError
        redis(redis_url).wrong_number_of_arguments_for @cmd
      rescue RuntimeError
        redis(redis_url).unknown @cmd
      rescue Errno::ECONNREFUSED
        redis(redis_url).connection_refused
      end
    end

    post '/config' do
      param = params[:param].intern
      value = params[:value]
      redis(redis_url).config(:set, param, value) and value
    end

    get '/stats' do
      content_type :json
      redis(Redmon[:redis_url]).redis.zrange(redis(redis_url).stats_key, count, -1).to_json
    end

    get '/discover' do
      Redmon.discover
      redirect '/'
    end

  end
end