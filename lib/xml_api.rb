# Provide an interface for the Silverpop XMLAPI to
# do basic interactions with the lead.
module Silverpopper::XmlApi
  # Authenticate through the xml api
  def api_login
    request_body = String.new
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)
    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.Login do
          xml.USERNAME(self.api_username)
          xml.PASSWORD(self.api_password)
        end
      end
    end

    doc = send_xml_api_request(request_body)
    self.session_id = result_dom(doc).elements['SESSIONID'].text
  end

  # Expire the Session Id and forget the stored Session Id
  def api_logout
    request_body = String.new
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)
    xml.Envelope do
      xml.Body do
        xml.Logout
      end
    end

    send_xml_api_request(request_body)
    self.session_id = nil
  end

  # Extracts a lists of databases
  #
  # === Options
  # :visibility
  #   The visibility of the databases to return
  # :list_type
  #   Type of entity to return:
  #     0 - databases
  #     1 - queries
  #     2 - databases/queries
  #     5 - test lists
  #     6 - seed lists
  #     13 - suppression lists
  #     15 - relational tables
  #     18 - contact lists
  # [:folder_id]
  #   Specify a particular folder from which to return databases
  # [:include_all_lists]
  #   To return all databases within subfolders
  # [:include_tags]
  #   To return all Tags associated with the database
  def get_lists(options={})
    visibility = options[:visibility]
    list_type = options[:list_type]
    folder_id = options[:folder_id]
    include_all_lists = options[:include_all_lists]
    include_tags = options[:include_tags]

    raise ArgumentError, "visibility option is required" unless visibility
    raise ArgumentError, "list_type option is required" unless list_type

    request_body = ''
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)

    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.GetLists do
          xml.VISIBILITY visibility
          xml.LIST_TYPE list_type
          xml.FOLDER_ID folder_id if folder_id.present?
          xml.INCLUDE_ALL_LISTS 'true' if include_all_lists.present?
          xml.INCLUDE_TAGS 'true' if include_tags.present?
        end
      end
    end

    doc = send_xml_api_request(request_body)
    results = {}

    result_dom(doc).elements.each do |item|
      next unless item.name == 'LIST'
      results[item.elements['ID'].text] = item.elements['NAME'].text
    end

    results
  end

  # Get job status by id
  # Return array with the job status and description
  #
  # job_id
  #   Identifies the Engage Background Job created and scheduled
  #   as a result of another API call.
  def get_job_status(job_id)
    raise ArgumentError, "Job ID is required" unless job_id.present?

    request_body = ''
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)

    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.GetJobStatus do
          xml.JOB_ID job_id
        end
      end
    end

    doc = send_xml_api_request(request_body)
    status = result_dom(doc).elements['JOB_STATUS'].text rescue nil
    desc = result_dom(doc).elements['JOB_DESCRIPTION'].text rescue nil
    [status, desc]
  end

  # Import list using already uploaded source and map files
  #
  # === Options
  # :map_file
  #   The name of the Mapping file in the upload directory of the
  #   FTP server to use for the import.
  # :source_file
  #   The name of the file containing the contact information to use
  #   in the import. This file must reside in the upload directory
  #   of the FTP Server.
  # [:file_encoding]
  #   Defines the encoding of the source file. Supported values are:
  #     UTF-8
  #     ISO-8859-1
  def import_list(options={})
    map_file = options[:map_file]
    source_file = options[:source_file]
    file_encoding = options[:file_encoding]

    raise ArgumentError, "map_file is required" unless map_file
    raise ArgumentError, "source_file is required" unless source_file

    request_body = ''
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)

    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.ImportList do
          xml.MAP_FILE map_file
          xml.SOURCE_FILE source_file
          xml.FILE_ENCODING file_encoding if file_encoding.present?
        end
      end
    end

    doc = send_xml_api_request(request_body)
    result_dom(doc).elements['JOB_ID'].text rescue nil
  end

  # Create a new contact list
  # Returns the list id if successfull
  #
  # === Options
  # :database_id
  #   The ID of the database the new Contact List will be associated with
  # :contact_list_name
  #   The name of the Contact List to be created
  # :visibility
  #   Defines the visibility of the Contact List being created:
  #     0 - private
  #     1 - shared
  def create_list(options={})
    database_id = options[:database_id]
    list_name = options[:contact_list_name]
    visibility = options[:visibility]

    raise ArgumentError, "database_id option is required" unless database_id
    raise ArgumentError, "list_name option is required" unless list_name
    raise ArgumentError, "visibility option is required" unless visibility

    request_body = ''
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)
    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.CreateContactList do
          xml.DATABASE_ID database_id
          xml.CONTACT_LIST_NAME list_name
          xml.VISIBILITY visibility
        end
      end
    end

    doc = send_xml_api_request(request_body)
    result_dom(doc).elements['CONTACT_LIST_ID'].text rescue nil
  end

  # Check if given list exists and create a new one if given
  # list not found in database. Return contact_list_id
  #
  # === Options
  #   Are the same as for get_lists and create_list methods
  # [force]
  #   Ignore lists_cache and ask silverpop server each time
  def sync_list(options, force=false)
    lists = (not force and self.cached_lists.any?) ? self.cached_lists : get_lists(options)
    self.cached_lists = lists

    name = options[:contact_list_name]

    if lists.values.include?(name)
      lists.keys[lists.values.index(name)]
    else
      create_list(options)
    end
  end

  # Insert a lead into silverpop
  #
  # expects a hash containing the strings: list_id, email and optionally
  # the string auto_reply.  any entries in the hash will be used to
  # populate the column name and values of the lead.
  # Returns the recipient id if successfully added, raises on error.
  def add_contact(options={})
    list_id = options.delete(:list_id)
    email = options.delete(:email)
    auto_reply = options.delete(:auto_reply)

    request_body = ''
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)
    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.AddRecipient do
          xml.LIST_ID list_id
          xml.CREATED_FROM '1'
          xml.SEND_AUTOREPLY 'true' if auto_reply

          xml.COLUMN do
            xml.NAME 'EMAIL'
            xml.VALUE email
          end

          options.each do |field, value|
            xml.COLUMN do
              xml.NAME field.to_s
              xml.VALUE value.to_s
            end
          end
        end
      end
    end

    doc = send_xml_api_request(request_body)
    result_dom(doc).elements['RecipientId'].text rescue nil
  end

  # Remove the contact from a list.
  #
  # expects a hash containing the strings: list_id and email.
  # Any additional columns passed will be treated as 'COLUMNS',
  # these COLUMNS are used in the case there is not a primary
  # key on email, and generally will not be used.
  def remove_contact(options={})
    list_id = options.delete(:list_id)
    email = options.delete(:email)

    request_body = ''
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)

    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.RemoveRecipient do
          xml.LIST_ID list_id
          xml.EMAIL email unless email.nil?
          options.each do |field, value|
            xml.COLUMN do
              xml.NAME field.to_s
              xml.VALUE value.to_s
            end
          end
        end
      end
    end

    send_xml_api_request(request_body)
    true
  end

  # Request details for lead.  
  #
  # expects a hash that contains the strings:
  # list_id, email.  Returns a hash containing properties
  # (columns) of the lead.
  def select_contact(options={})
    contact_list_id = options.delete(:list_id)
    email = options.delete(:email)
    request_body = String.new
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)

    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.SelectRecipientData do
          xml.LIST_ID contact_list_id
          xml.EMAIL email
        end
      end
    end

    doc = send_xml_api_request(request_body)

    result_dom(doc).elements['COLUMNS'].collect do |i|
      i.respond_to?(:elements) ? [i.elements['NAME'].first, i.elements['VALUE'].first] : nil
    end.compact.inject(Hash.new) do |hash, value|
      hash.merge({value[0].to_s => (value[1].blank? ? nil : value[1].to_s)})
    end
  end

  # Update the column values of a lead in silverpop.
  #
  # expects a hash that contains the string: list_id, email.  
  # additional values in the hash will be passed as column values, 
  # with the key being the column name, and the value being the value.
  # Returns the Recipient Id.
  def update_contact(options={})
    contact_list_id = options.delete(:list_id)
    email = options.delete(:email)

    request_body = String.new
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)

    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.UpdateRecipient do
          xml.LIST_ID contact_list_id
          xml.OLD_EMAIL email

          options.each do |field, value|
            xml.COLUMN do
              xml.NAME field
              xml.VALUE value
            end
          end
        end
      end
    end

    doc = send_xml_api_request(request_body)
    result_dom(doc).elements['RecipientId'].text rescue nil
  end

  # Send an email to a user with a pre existing template.  
  #
  # expects a hash containing the strings: email, mailing_id.  
  def send_mailing(options={})
    email, mailing_id = options.delete(:email), options.delete(:mailing_id)
    request_body = String.new
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)

    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.SendMailing do
          xml.MailingId mailing_id
          xml.RecipientEmail email
        end
      end
    end

    send_xml_api_request(request_body)
    true
  end

  # Schedule a mailing to be sent to an entire list. 
  # expects a hash containing the keys with the strings: 
  # list_id, template_id, mailing_name, subject, from_name, 
  # from_address, reply_to.  Additional entries in the argument 
  # will be treated as the substitution name, and substitution values.
  # Returns the Mailing Id.
  def schedule_mailing(options={})
    list_id = options.delete(:list_id)
    template_id = options.delete(:template_id)
    mailing_name = options.delete(:mailing_name)
    subject = options.delete(:subject)
    from_name = options.delete(:from_name)
    from_address = options.delete(:from_address)
    reply_to = options.delete(:reply_to)

    request_body = String.new
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)

    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.ScheduleMailing do
          xml.TEMPLATE_ID template_id
          xml.LIST_ID list_id
          xml.SEND_HTML
          xml.SEND_TEXT
          xml.MAILING_NAME mailing_name
          xml.SUBJECT subject
          xml.FROM_NAME from_name if from_name != ''
          xml.FROM_ADDRESS from_address if from_address != ''
          xml.REPLY_TO reply_to if reply_to != ''

          if options.length > 0
            xml.SUBSTITUTIONS do
              options.each do |key, value|
                xml.SUBSTITUTION do
                  xml.NAME key
                  xml.VALUE value
                end
              end
            end
          end
        end
      end
    end

    doc = send_xml_api_request(request_body)
    result_dom(doc).elements['MAILING_ID'].first.to_s
  end

  protected

  # Given a silverpop api response document, was the api call successful?
  def silverpop_successful?(doc)
    result_dom(doc).elements['SUCCESS'].text.downcase == 'true' rescue false
  end

  # Given a silverpop api response document, parse out the result
  def result_dom(dom)
    dom.elements['Envelope'].elements['Body'].elements['RESULT']
  end

  # Execute an xml api request, and parse the response
  # Given a parsed xml response document for the silverpop api call
  # raise the given message unless the call was successful
  def send_xml_api_request(markup, message = nil)
    result = send_request(markup, "#{self.api_url}/XMLAPI#{@session_id}", 'api')
    doc = REXML::Document.new(result)

    return doc if silverpop_successful?(doc)

    raise message || ("#{doc.elements['Envelope'].elements['Body'].elements['Fault'].
      elements['FaultString'].text} (Error ID: #{doc.elements['Envelope'].elements['Body'].
      elements['Fault'].elements['detail'].elements['error'].elements['errorid'].
      text})" rescue "Operation failed: #{markup}")
  end

  # A helper method for setting the session_id when logging in
  def session_id=(session_id)
    @session_id = session_id.blank? ? nil : ";jsessionid=#{session_id}"
  end
end
