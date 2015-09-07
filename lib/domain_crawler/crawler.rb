# coding: utf-8
require "thread"

module DomainCrawler
  class Crawler
    def initialize(keyword)
      @search_keyword = SearchKeyword.new
      @search_keyword.add keyword
      @history = History.new
    end

    def get(depth = 3)
      each_page_in_threads @search_keyword do |page|
        craw page, depth do |host|
          yield host
        end
      end
    end

    private

    TERMINATOR = Object.new

    def each_page_in_threads(enumerable, n_thread = 5)
      queue = SizedQueue.new(n_thread)
      threads = n_thread.times.map do
        Thread.new do
          loop do
            v = queue.shift
            break if v.equal?(TERMINATOR)
            yield v
          end
        end
      end
      enumerable.each_page { |v| queue << v }
      n_thread.times { queue << TERMINATOR }
      threads.each(&:join)
      enumerable
    end

    def craw(page, depth, &block)
      return if page.class != Mechanize::Page
      if exists?(page.uri.host)
        return
      else
        check_and_call page.uri.host, &block
      end

      page.links.each do |link|
        begin
          if link.uri && link.uri.host && link.uri.host != page.uri.host
            unless exists?(link.uri.host)
              if depth <= 0
                check_and_call link.uri.host, &block
              else
                craw(link.click, depth - 1, &block)
              end
            end
          end
        rescue => e
          p e
        end
      end
    end

    def check_and_call(host, &block)
      begin
        block.call get_domain(host)
      end
      @history.add host
    end

    def exists?(host)
      @history.include? host
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
