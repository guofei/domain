# coding: utf-8

module DomainCrawler
  class History
    include Singleton
    KEY_URL = 'url'
    KEY_HISTORY = 'history'
    NS = Rails.application.secrets.redis_ns
    HOST = Rails.application.secrets.redis_host
    PORT = Rails.application.secrets.redis_port
    DB = Rails.application.secrets.redis_db

    def redis
      @redis ||= Redis::Namespace.new(
        NS,
        redis: Redis.new(host: HOST, port: PORT, db: DB)
      )
    end

    # get next url
    def pop
      redis.spop KEY_URL
    end

    def started?
      redis.scard(KEY_URL) > 0
    end

    def empty?
      redis.scard(KEY_URL) <= 0
    end

    # push domain to scheduler
    def push(url)
      # return false unless check_url url
      return false if redis.sismember KEY_HISTORY, url

      redis.multi do
        redis.sadd KEY_HISTORY, url
        redis.sadd KEY_URL, url
      end
      true
    end

    # private

    # def check_url(url)
    #   url =~ /\A#{URI.regexp(%w(http, https))}\z/
    # end
  end
end
