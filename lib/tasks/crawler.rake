namespace :crawler do
  task get: :environment do
    crawler = DomainCrawler::Crawler.new("c++ std vector")
    w = Whois::Client.new
    crawler.get 3 do |host|
      p host
      next if Domain.exists?(url: host)
      dinfo = w.lookup(host)
      if dinfo.registered?
        if dinfo.expires_on
          Domain.create(url: host, expires_on: dinfo.expires_on)
        end
      else
        Domain.create(url: host, expires_on: Time.now.prev_year)
      end
    end
  end
end
