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
      pages = @search_keyword.pages
      Parallel.each(pages, in_threads: 5) do |page|
        craw page, depth do |host|
          yield host
        end
      end
    end

    private

    def craw(page, depth, &block)
      return if page.class != Mechanize::Page
      return if exists?(page.uri.host)

      run_block page.uri.host, &block

      return if depth <= 0

      page.links.each do |link|
        if link.uri && link.uri.host && link.uri.host != page.uri.host
          next if exists?(link.uri.host)
          begin
            page = link.click
          rescue
            next
          end
          craw(page, depth - 1, &block)
        end
      end
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

  class Search
    def initialize
      @agent = Mechanize.new
      @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @agent.max_history = 1
    end

    def s(keyword)
      form = google_form
      form.q = keyword
      page = @agent.submit(form)
      while page
        page.links.each do |link|
          yield link
        end
        page = next_page page
      end
    end

    private

    def next_page(page)
      link = page.link_with(text: '次へ')
      if link.nil?
        nil
      else
        link.click
      end
    end

    def google_form
      google_page = @agent.get('http://www.google.co.jp/webhp?hl=ja')
      google_form = google_page.form('f')
      google_form
    end
  end

  class SearchKeyword
    def initialize
      @search = Search.new
    end

    def add(keyword)
      @keywords ||= []
      @keywords << keyword
    end

    def pages
      pages = []
      each_page { |page| pages << page }
      pages
    end

    def each_page
      @keywords.each do |keyword|
        @search.s keyword do |link|
          begin
            if link.href.include?('/url?q=http') &&
               !link.href.include?('google') &&
               link.uri.host.nil?
              yield link.click
            end
          rescue => e
            p e
          end
        end
      end
    end
  end

  class History
    def initialize
      @hash = {}
      @mutex = Mutex.new
    end

    def add(host)
      @mutex.synchronize do
        @hash[host] = true
      end
    end

    def include?(host)
      @mutex.synchronize do
        @hash[host]
      end
    end
  end
end

# crawler = Crawler.new("c++ std vector")
# crawler.get 2 do |host|
# p host
# end
