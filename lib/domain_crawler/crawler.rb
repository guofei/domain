# coding: utf-8
require 'thread'
require 'parallel'

module DomainCrawler
  class Error < StandardError; end

  class Crawler
    def initialize(keyword)
      @search_keyword = SearchKeyword.new
      @search_keyword.add keyword
      @history = History.new
    end

    def get(depth = 20)
      uris = @search_keyword.uris
      Parallel.each(uris, in_threads: 5) do |uri|
        craw uri, depth do |host|
          yield host
        end
      end
    end

    private

    def craw(uri, depth, &block)
      return if exists?(uri.host)

      run_block uri.host, &block

      return if depth <= 0

      get_links(uri).each do |new_uri|
        return unless different_host?(uri, new_uri)
        next if exists?(new_uri.host)
        craw(new_uri, depth - 1, &block)
      end
    end

    def get_links(uri)
      uris = []

      file = open(uri)
      doc = Nokogiri::HTML(file)
      file.close

      doc.css('a').each do |link|
        begin
          uris << URI.parse(link['href'])
        rescue
          next
        end
      end
      uris
    rescue
      []
    end

    def different_host?(uri, new_uri)
      return uri.host != new_uri.host
    rescue
      false
    end

    def run_block(host, &block)
      domain = get_domain host
      @history.add domain
      block.call domain
    rescue
      nil
    end

    def exists?(host)
      @history.include? get_domain(host)
    rescue
      true
    end

    def get_domain(host)
      PublicSuffix::List.private_domains = false
      PublicSuffix.parse(host).domain
    end
  end
end

# crawler = Crawler.new("c++ std vector")
# crawler.get 2 do |host|
# p host
# end
