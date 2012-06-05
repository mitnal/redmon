module Redmon
  module Helpers

    def connections
      @connections ||= []
    end

    def redis_url
      params[:redis] || Redmon[:redis_url]
    end

    def redis(url)
      if connection = connections.select { |con| con && con[:url] == url }.first
        connection[:redis]
      else
        redis = Redmon::Redis.new(url)
        connections << { url: url, redis: redis }
        redis
      end
    end

    def prompt(url = Redmon[:redis_url])
      "#{url.gsub('://', ' ')}>"
    end

    def poll_interval
      Redmon[:poll_interval] * 1000
    end

    def count
      -(params[:count] ? params[:count].to_i : 1)
    end

  end
end