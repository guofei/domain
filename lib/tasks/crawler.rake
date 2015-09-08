namespace :crawler do
  task get: :environment do
    crawler = DomainCrawler::Crawler.new('c++ std vector')
    crawler.get do |host|
      p host
      begin
        whois = Whois.whois(host)
        if whois.available?
          unless Domain.exists?(url: host)
            Domain.create(url: host, expires_on: Time.now.prev_year, deleted: true)
          end
        else
          if whois.expires_on
            unless Domain.exists?(url: host)
              Domain.create(url: host, expires_on: whois.expires_on)
            end
          end
        end
      rescue => e
        p e
      end
    end
  end
end
