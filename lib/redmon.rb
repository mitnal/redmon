require 'active_support/core_ext'
require 'eventmachine'
require 'haml'
require 'redis'
require 'sinatra/base'
require 'thin'

module Redmon
  extend self

  attr_reader :opts

  @opts = {
    :web_interface  => ['0.0.0.0', 4567],
    :redis_url      => 'redis://127.0.0.1:6379', # Redis to store data.
    :redis_urls     => [], # Redis instances that should be monitored.
    :discover       => true,
    :discover_range => { from: 6379, to: 6400 },
    :namespace      => 'redmon',
    :worker         => true,
    :poll_interval  => 10
  }

  def run(opts={})
    @opts.merge! opts
    discover(@opts[:discover_range][:from], @opts[:discover_range][:to]) if @opts[:discover]
    start_em
  rescue Exception => e
    log e.backtrace.inspect
    log "!!! Redmon has shit the bed, restarting... #{e.message}"
    sleep(1); run(opts)
  end

  def start_em
    EM.run do
      trap 'TERM', &method(:shutdown)
      trap 'INT',  &method(:shutdown)
      start_app    if opts[:web_interface]
      start_worker if opts[:worker]
    end
  end

  def start_app
    app = Redmon::App.new
    Thin::Server.start(*opts[:web_interface], app)
    log "listening on http##{opts[:web_interface].join(':')}"
  rescue Exception => e
    log "Can't start Redmon::App. port in use?  Error #{e}"
  end

  def start_worker
    @opts[:redis_urls].each do |redis_url|
      Worker.new(redis_url).run!
    end
  end

  def shutdown
    EM.stop
  end

  def log(msg)
    puts "[#{Time.now.strftime('%y-%m-%d %H:%M:%S')}] #{msg}"
  end

  def [](option)
    opts[option]
  end

  def discover(from = @opts[:discover_range][:from], to = @opts[:discover_range][:to])
    (from..to).each do |port|
      begin
        url = "redis://127.0.0.1:#{port}"
        ::Redis.connect(url: url).ping
        @opts[:redis_urls] << url
      rescue ::Redis::CannotConnectError
        # do nothing
      rescue Errno::ECONNREFUSED
        # do nothing
      rescue Errno::ECONNRESET
        # do nothing
      end
    end
    @opts[:redis_urls] << @opts[:redis_url]
    @opts[:redis_urls].uniq!.sort!
  end

end

require 'redmon/redis'
require 'redmon/helpers'
require 'redmon/app'
require 'redmon/worker'