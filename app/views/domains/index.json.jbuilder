json.array!(@domains) do |domain|
  json.extract! domain, :id, :url, :expires_on
  json.url domain_url(domain, format: :json)
end
