module Silverpopper::Transact

  def send_transact_mail(options={})
    email          = options.delete('email')
    transaction_id = options.delete('transaction_id')
    campaign_id    = options.delete('campaign_id')

    request_body = String.new
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)

    xml.instruct!
    xml.XTMAILING{
      xml.CAMPAIGN_ID campaign_id
      xml.TRANSACTION_ID transaction_id
      xml.SEND_AS_BATCH 'false'
      xml.RECIPIENT{
        xml.EMAIL email
        xml.BODY_TYPE 'HTML'
        options.each do |key, value|
          xml.PERSONALIZATION{
            xml.TAG_NAME key
            xml.VALUE value
          }
        end
      }
    }

    begin
      ret_val = send_transact_request(request_body)
    rescue
      return -2, 'Internal error while processing http request'
    end

    doc = REXML::Document.new(ret_val)
    raise "failure to create transact mailing" if doc == nil || doc.elements['XTMAILING_RESPONSE'] == nil || doc.elements['XTMAILING_RESPONSE'].elements['ERROR_CODE'] == nil

    doc.elements['XTMAILING_RESPONSE'].elements['RECIPIENTS_RECEIVED'].text
  end

end
