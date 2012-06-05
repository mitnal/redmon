module Redmon
  class Redis

    UNSUPPORTED = [
      :eval,
      :psubscribe,
      :punsubscribe,
      :subscribe,
      :unsubscribe,
      :unwatch,
      :watch
    ]

    def initialize(url = Redmon[:redis_url])
      @redis_url = url.gsub(/\w*:\w*@/, '')
    end

    def redis
      @redis ||= ::Redis.connect(:url => redis_url)
    end

    def ns
      Redmon[:namespace]
    end

    def redis_url
      @redis_url ||= Redmon[:redis_url].gsub(/\w*:\w*@/, '')
    end

    def redis_host
      @redis_host ||= redis_url.gsub('redis://', '')
    end

    def redis_port
      @redis_port ||= redis_url.match(/.*:(\d{4})/)[1].to_i
    end

    def config
      redis.config :get, '*' rescue {}
    end

    def unquoted
      %w{string OK} << '(empty list or set)'
    end

    def supported?(cmd)
      !UNSUPPORTED.include? cmd
    end

    def empty_result
      '(empty list or set)'
    end

    def unknown(cmd)
      "(error) ERR unknown command '#{cmd}'"
    end

    def wrong_number_of_arguments_for(cmd)
      "(error) ERR wrong number of arguments for '#{cmd}' command"
    end

    def connection_refused
      "Could not connect to Redis at #{redis_url.gsub(/\w*:\/\//, '')}: Connection refused"
    end

    def stats_key
      "#{ns}:redis:#{redis_host}:stats"
    end
  end
end