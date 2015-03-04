# coding: utf-8
require "thread"

module DomainCrawler
  class Crawler
    def initialize(keyword)
      @search_keyword = SearchKeyword.new
      @search_keyword.add keyword
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

    def each_page_in_threads(enumerable, n_thread = 10)
      queue = SizedQueue.new(n_thread)
      threads = n_thread.times.map do
        Thread.new do
          while true
            v = queue.shift
            break if v.equal?(TERMINATOR)
            yield v
          end
        end
      end
      enumerable.each_page{|v| queue << v }
      n_thread.times{ queue << TERMINATOR }
      threads.each(&:join)
      enumerable
    end

    def craw(page, depth, &block)
      return if page.class != Mechanize::Page
      unless exists?(page.uri.host)
        block.call get_domain(page.uri.host)
      else
        return
      end

      page.links.each do |link|
        begin
          if link.uri && link.uri.host && link.uri.host != page.uri.host
            unless exists?(link.uri.host)
              if depth <= 0
                block.call get_domain(link.uri.host)
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

    def exists?(host)
      if host =~ /.+\..+\..+/ && !host.include?("ac.jp")
        true
      else
        Domain.exists?(url: get_domain(host))
      end
    end

    def get_domain(host)
      dm = PublicSuffix.parse(host).domain
      dm.sub(/.*?([^.]+(\.com))$/, "\\1")
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
      while page do
        page.links.each do |link|
          yield link
        end
        page = next_page page
      end
    end

    private

    def next_page(page)
      link = page.link_with(text: "次へ")
      if link.nil?
        nil
      else
        link.click
      end
    end

    def google_form
      google_page = @agent.get('http://www.google.co.jp/webhp?hl=ja')
      google_form = google_page.form('f')
    end
  end

  class SearchKeyword
    def initialize
      @search = Search.new
    end

    def add(keyword)
      @keywords ||= Array.new
      @keywords << keyword
    end

    def each_page
      @keywords.each do |keyword|
        @search.s keyword do |link|
          begin
	    if link.href.include?("/url?q=http") &&
               !link.href.include?("google") &&
               link.uri.host == nil
              yield link.click
            end
          rescue => e
	    p e
          end
        end
      end
    end
  end
end


#crawler = Crawler.new("c++ std vector")
#crawler.get 2 do |host|
#  p host
#end
