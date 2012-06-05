module Redmon
  class Worker

    def initialize(monitor_redis_url, record_redis_url = Redmon[:redis_url])
      @redis_url        = monitor_redis_url
      @record_redis_url = record_redis_url
    end

    def run!
      EM::PeriodicTimer.new(interval) {record_stats}
    end

    def record_stats
      record_redis.redis.zadd redis.stats_key, *stats
    end

    def redis
      @redis ||= Redmon::Redis.new(@redis_url)
    end

    def record_redis
      @record_redis ||= Redmon::Redis.new(@record_redis_url)
    end

    def stats
      stats = redis.redis.info.merge! \
        :dbsize  => redis.redis.dbsize,
        :time    => ts = Time.now.to_i * 1000,
        :slowlog => entries(redis.redis.slowlog :get)
      [ts, stats.to_json]
    end

    def entries(slowlog)
      sort(slowlog).map do |entry|
        {
          :id           => entry.shift,
          :timestamp    => entry.shift * 1000,
          :process_time => entry.shift,
          :command      => entry.shift.join(' ')
        }
      end
    end

    def sort(slowlog)
      slowlog.sort_by{|a| a[2]}.reverse!
    end

    def interval
      Redmon[:poll_interval]
    end

  end
end