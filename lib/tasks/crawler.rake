namespace :crawler do
  task get: :environment do
    crawler = DomainCrawler::Crawler.new("c++ std vector")
    w = Whois::Client.new
    crawler.get do |host|
      p host
      begin
        whois = w.lookup(host)
        if whois.registered?
          if whois.expires_on
            Domain.create(url: host, expires_on: whois.expires_on)
          else
            p "unknow: #{host}"
            Domain.create(url: host, expires_on: Time.now.next_year, unknown: true)
          end
        else
          Domain.create(url: host, expires_on: Time.now.prev_year)
        end
      rescue Exception => e
	p e
      end
    end
  end
end
