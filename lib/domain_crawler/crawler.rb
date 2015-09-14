# coding: utf-8

module DomainCrawler
  class Error < StandardError; end

  class Crawler
    def initialize(url)
      history.push URI.parse(url)
    end

    def craw
      download = Downloader.new
      lam = lambda{ history.pop || Parallel::Stop }
      loop do
        Parallel.each(lam, in_threads: 5) do |url|
          download.links(url).each do |uri|
            pushed = history.push uri
            next unless pushed
            begin
              yield get_domain(uri)
            rescue
              next
            end
          end
        end
        break if history.empty?
      end
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
