namespace :crawler do
  task get: :environment do
    url = 'http://www.yahoo.co.jp/'
    crawler = DomainCrawler::Crawler.new(url)
    crawler.craw do |host|
      break if Domain.exists?(url: host)
      p host
      whois = Whois.whois(host)
      if whois.available?
        Domain.create(url: host, expires_on: Time.now.prev_year, deleted: true)
      else
        if whois.expires_on
          Domain.create(url: host, expires_on: whois.expires_on)
        end
      end
    end
  end
end
