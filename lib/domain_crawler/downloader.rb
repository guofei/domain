# coding: utf-8
require 'open-uri'

module DomainCrawler
  # Download from uri or link(string)
  class Downloader
    # @param url URI or String
    # @return [URI]
    def links(url)
      doc = doc url
      return [] if doc.nil?

      result = []
      doc.css('a').each do |link|
        next unless accept? link['href']
        # new_uri = compose_uri get_uri(url), link['href']
        new_uri = get_uri link['href']
        result << new_uri unless new_uri.nil?
      end
      result
    end

    # @param url URI or String
    # @return Nokogiri::HTML::Document
    def doc(url)
      uri = get_uri url
      return nil if uri.nil?

      # file = open(uri, 'User-Agent' => 'Googlebot/2.1')
      file = open(uri)
      doc = Nokogiri::HTML(file)
      file.close
      doc
    rescue
      nil
    end

    private

    # @param url URI or String
    # @return URI or nil
    def get_uri(url)
      return url if url.class == URI::HTTP || url.class == URI::HTTPS

      uri = URI.parse url
      return uri if uri.class == URI::HTTP || uri.class == URI::HTTPS
      nil
    rescue
      nil
    end

    # @param uri URI
    # @param href String
    # @return URI or nil
    def compose_uri(uri, href)
      new_uri = get_uri href
      return new_uri unless new_uri.nil?
      new_uri = URI.join(uri.to_s, href)
      get_uri new_uri
    rescue
      nil
    end

    # @param href String
    # @return boolean
    def accept?(href)
      accepted_formats = ['', '.html', '.htm', '.cgi']
      accepted_formats.include? File.extname(href)
    rescue
      false
    end
  end

  # url = 'http://www.yahoo.co.jp'
  # url = 'http://www.quickmesh.co.jp'
  # uri = URI.parse url
  # d = Downloader.new
  # links_a = d.links uri
  # links_a.map { |link| p link.to_s }
end
