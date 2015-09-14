# coding: utf-8

module DomainCrawler
  class Error < StandardError; end

  class Crawler
    def initialize(url)
      history.push URI.parse(url)
    end

    def craw
      download = Downloader.new
      # lam = lambda{ history.pop || Parallel::Stop }
      n_thread = 5
      Parallel.each(n_thread.times, in_threads: n_thread) do |_|
        count = 0
        loop do
          url = history.pop
          if url.nil?
            sleep 10
            break if count == 10
            count += 1
            next
          end
          count = 0
          download.links(url).each do |uri|
            pushed = history.push uri
            next unless pushed
            begin
              yield get_domain(uri)
            rescue
              next
            end
          end
          # break if history.empty?
        end
      end
      p 'end thread!!!'
    end

    private

    def history
      History.instance
    end

    def get_domain(uri)
      PublicSuffix::List.private_domains = false
      PublicSuffix.parse(uri.host).domain
    end
  end
end

# crawler = Crawler.new("c++ std vector")
# crawler.get 2 do |host|
# p host
# end
