# coding: utf-8
module DomainCrawler
  class Crawler
    def initialize(keyword)
      @search_keyword = SearchKeyword.new
      @search_keyword.add keyword
    end

    def get(depth = 3)
      @search_keyword.each_page do |page|
        craw page, depth do |host|
          yield host
        end
      end
    end

    private

    def craw(page, depth, &block)
      return if page.class != Mechanize::Page
      return if Domain.exists?(get_domain page.uri.host)

      if depth <= 0
        page.links.each do |link|
          if link.uri && link.uri.host
            block.call get_domain(link.uri.host)
          end
        end
      else
        block.call get_domain(page.uri.host)
        page.links.each do |link|
          if link.uri && link.uri.host
            unless Domain.exists?(get_domain link.uri.host)
              begin
                page = link.click
                craw(page, depth - 1, &block)
              rescue => e
                  p e
              end
            end
          end
        end
      end
    end

    def get_domain(host)
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
      google_page = @agent.get('http://www.google.co.jp/')
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
          if link.href.include?("/url?q=") && !link.href.include?("google")
            yield link.click
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
