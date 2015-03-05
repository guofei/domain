namespace :crawler do
  task get: :environment do
    crawler = DomainCrawler::Crawler.new("c++ std vector")
    crawler.get do |host|
      p host
      begin
        IPSocket::getaddress(host)
      rescue Exception => e
        begin
          whois = Whois.whois(host)
          if whois.registered?
            if whois.expires_on
              unless Domain.exists?(url: host)
                Domain.create(url: host, expires_on: whois.expires_on)
              end
            end
          else
            unless Domain.exists?(url: host)
              Domain.create(url: host, expires_on: Time.now.prev_year, deleted: true)
            end
          end
        rescue Exception => e
          p e
        end
      end
    end
  end
end
