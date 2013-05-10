module SearchesHelper

  def fetch_result(url_string)
    url = URI.parse(URI.escape(url_string))
    res = Net::HTTP.get_response(url)
    doc = XmlSimple.xml_in res.body
    json = JSON.pretty_generate(JSON.parse(doc.to_json))
    return json
  end

end
