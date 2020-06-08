# Set of methods that are used by both XMLAPI and Transact API
module Silverpopper::Common

  # Dispatch an API call to the given url, with content headers
  # set appropriately.  Raise unless successful and return the
  # raw response body
  def send_request(markup, url, api_host)
    resp = HTTParty.post(url, :body => markup, :headers => {
      'Content-type' => 'text/xml;charset=UTF-8',
      'X-Intended-Host' => api_host + self.pod.to_s
    })
    raise "Request Failed" unless resp.code == 200 || resp.code == 201

    resp.body
  end

  def send_oauth_request(markup, url, api_host)
    resp = HTTParty.post(url, body: markup, headers: {
      "Content-type" => "text/xml;charset=UTF-8",
      "Authorization" => "Bearer #{access_token}"
    })

    raise "Request Failed" unless resp.code == 200 || resp.code == 201

    resp.body
  end

  def request_access_token(body, url)
    resp = HTTParty.post(url, body: body, headers: {
      'Content-type' => "application/x-www-form-urlencoded"
    })
    raise "Request Failed" unless resp.code == 200 || resp.code == 201

    resp.body
  end

  def apply_xml_options!(xml, options)
    options.stringify_keys.each do |key, value|
      if [String, Fixnum, Float].include?(value.class)
        eval("xml.#{key.upcase}(value)")
      elsif value.is_a?(Array)
        value.each { |suboptions| apply_xml_options!(xml, suboptions) }
      elsif value.is_a?(Hash)
        eval("xml.#{key.upcase} { apply_xml_options!(xml, value) }")
      elsif value.is_a?(TrueClass)
        eval("xml.#{key.upcase}")
      end
    end

    nil
  end
end
