# coding: utf-8
module DomainCrawler
  class Search
    attr_reader :agent

    def initialize
      @agent = Mechanize.new
      @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @agent.max_history = nil
    end

    def s(keyword)
      form = google_form
      form.q = keyword
      page = agent.submit(form)
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
      google_page = agent.get('http://www.google.co.jp/webhp?hl=ja')
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

    def uris
      uris = []
      each_page { |page| uris << page.uri }
      uris
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
end
