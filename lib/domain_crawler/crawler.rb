# coding: utf-8

module DomainCrawler
  class Error < StandardError; end

  class Crawler
    def initialize(url)
      history.push url
    end

    def craw
      loop do
        lam = lambda{ history.pop || Parallel::Stop }
        Parallel.each(lam, in_threads: 5) do |url|
          p url
          download = Downloader.new
          download.links(url).each do |uri|
            history.push uri.to_s
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
