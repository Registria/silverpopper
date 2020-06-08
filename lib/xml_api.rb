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
    self.session_id = result_dom(doc)['SESSIONID']
  end

  # Expire the Session Id and forget the stored Session Id
  def api_logout
    return if @session_id.nil?

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

  def oauth_login
    request_body = {
      grant_type: "refresh_token",
      client_id: self.client_id,
      client_secret: self.client_secret,
      refresh_token: self.refresh_token
    }

    doc = request_access_token(request_body, @oauth_url)
    self.access_token = JSON.parse(doc).dig("access_token")
  end

  # Get job status by id
  # Return array with the job status and description
  #
  # job_id
  #   Identifies the Engage Background Job created and scheduled
  #   as a result of another API call.
  def get_job_status(job_id)
    raise ArgumentError, "job_id is required" unless job_id.present?

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
    status = result_dom(doc)['JOB_STATUS'] rescue nil
    desc = result_dom(doc)['JOB_DESCRIPTION'] rescue nil
    [status, desc]
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
    result_dom(doc)['LIST']
  end

  # Check if given list exists and create a new one if given
  # list not found in database. Return contact_list_id
  #
  # === Options
  #   Are the same as for get_lists and create_list methods
  # [:contact_list_name]
  #   To check list matches more accuratelly by comparing list
  #   parent name
  # [force]
  #   Ignore lists_cache and ask silverpop server each time
  def get_list(options, force = false)
    lists = if force or not self.cached_lists.any?
      self.cached_lists = get_lists(options)
    else
      self.cached_lists
    end

    name = options[:contact_list_name]
    parent_name = options.delete(:parent_name)

    raise ArgumentError, ":contact_list_name is required" unless name

    lists.find { |l|
      if parent_name.present?
        l['NAME'] == name and l['PARENT_NAME'] == parent_name
      else
        l['NAME'] == name
      end
    }
  end

  # Check if given list exists and create a new one if given
  # list not found in database. Return contact_list_id
  #
  # === Options
  # Same as for get_list call
  def sync_list(options, force = false)
    (get_list(options, force)['ID'] rescue nil) || create_list(options)
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

    raise ArgumentError, ":map_file is required" unless map_file
    raise ArgumentError, ":source_file is required" unless source_file

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
    result_dom(doc)['JOB_ID'] rescue nil
  end

  # Export list using LIST_ID
  #
  # === Options
  # :list_id
  #   Unique identifier for the database, query, or contact list Engage is exporting.
  # :export_type
  #   Specifies which contacts to export. Valid values are:
  #     ALL – export entire database.
  #     OPT_IN – export only currently opted-in contacts.
  #     OPT_OUT – export only currently opted-out contacts.
  #     UNDELIVERABLE – export only contacts who are currently marked as undeliverable.
  # :export_format
  #   Specifies the format (file type) for the exported data. Valid values are:
  #     CSV – create a comma-separated values file
  #     TAB – create a tab-separated values file
  #     PIPE – create a pipe-separated values file
  # [:email]
  #   If specified, this email address receives notification when the job is complete.
  # [:file_encoding]
  #   Defines the encoding of the source file. Supported values are:
  #     UTF-8
  #     ISO-8859-1
  # [:add_to_stored_files]
  #   Use the ADD_TO_STORED_FILES parameter to write the output to the
  #   Stored Files folder within Engage.
  #   If you omit the ADD_TO_STORED_FILES parameter, Engage will move
  #   exported files to the download directory of the user ’ s FTP space.
  # [:date_start]
  #   Specifies the beginning boundary of information to export (relative to
  #   the last modified date).If time is included, it must be in 24-hour format.
  # [:date_end]
  #   Specifies the ending boundary of information to export (relative to the
  #   last modified date).If time is included, it must be in 24-hour format.
  # [:list_date_format]
  #   Used to specify the date format of the date fields in your exported file if date
  #   format differs from "mm/dd/yyyy" (month, day, and year can be in any order
  #   you choose).
  #   Valid values for Month are :
  #     mm (e.g. 01)
  #     m (e.g. 1)
  #     mon (e.g.Jan)
  #     month (e.g.January)
  #   Valid values for Day are :
  #     dd (e.g. 02)
  #     d (e.g. 2)
  #   Valid values for Year are :
  #     yyyy (e.g. 1999)
  #     yy (e.g. 99)
  #   Separators may be up to two characters in length and can consist of periods,
  #   commas, question marks, spaces, and forward slashes (/).
  #   Examples:
  #     If dates in your file are formatted as "Jan 2, 1975" your
  #     LIST_DATE_FORMAT would be "mon d, yyyy".
  #
  #     If dates in your file are formatted as "1975/ 09/02" your
  #     LIST_DATE_FORMAT would be "yyyy/mm/dd".
  def export_list(options={})
    list_id = options[:list_id]

    raise ArgumentError, ":list_id option is required" unless list_id.present?

    export_type = options[:export_type] || "ALL"
    export_format = options[:export_format] || "CSV"
    email = options[:email]
    file_encoding = options[:file_encoding]
    add_to_stored_files = options[:add_to_stored_files]
    date_start = options[:date_start]
    date_end = options[:date_end]
    list_date_format = options[:list_date_format]

    request_body = ''
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)
    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.ExportList do
          xml.LIST_ID list_id
          xml.EXPORT_TYPE export_type
          xml.EXPORT_FORMAT export_format

          xml.EMAIL email if email.present?
          xml.FILE_ENCODING file_encoding if file_encoding.present?
          xml.ADD_TO_STORED_FILES add_to_stored_files if add_to_stored_files
          xml.DATE_START date_start if date_start.present?
          xml.DATE_END date_end if date_end.present?
          xml.LIST_DATE_FORMAT list_date_format if list_date_format.present?
        end
      end
    end

    doc = send_xml_api_request(request_body)
    result_dom(doc)
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

    raise ArgumentError, ":database_id option is required" unless database_id
    raise ArgumentError, ":list_name option is required" unless list_name
    raise ArgumentError, ":visibility option is required" unless visibility

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
    result_dom(doc)['CONTACT_LIST_ID']
  end

  # Create a new classic query of an Engage database.
  # Returns created query id if successful
  #
  # === Options
  # :query_name
  #   The name of the new query
  # :parent_list_id
  #   The id of the database being queried
  # :visibility
  #   Visibility of the new query, default is 0
  # :criteria
  #   Describes the expressions to perform one or more columns
  #   in the database
  # [:behavior]
  #   Filters mailing contacts by their activity
  def create_classic_query(options)
    raise ArgumentError, "Query name is not present" unless options[:query_name]
    raise ArgumentError, "Parent list id is not present" unless options[:parent_list_id]
    raise ArgumentError, "Criteria is required" unless options[:criteria]

    options[:visibility] ||= 0

    request_body = ''
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)
    xml.instruct!

    xml.Envelope do
      xml.Body do
        xml.CreateQuery do
          xml.QUERY_NAME options[:query_name]
          xml.PARENT_LIST_ID options[:parent_list_id]
          xml.VISIBILITY options[:visibility]

          xml.PARENT_FOLDER_ID options[:parent_folder_id] if options.has_key?(:parent_folder_id)
          xml.SELECT_COLUMNS options[:select_columns] if options.has_key?(:select_columns)
          xml.ALLOW_FIELD_CHANGE options[:allow_field_change] if options.has_key?(:allow_field_change)

          xml.CRITERIA do
            xml.TYPE options[:criteria][:type] if options[:criteria].has_key?(:type)

            options[:criteria][:expressions].each do |exp|
              xml.EXPRESSION do
                xml.TYPE exp[:type] if exp.has_key?(:type)
                xml.COLUMN_NAME exp[:column_name] if exp.has_key?(:column_name)
                xml.OPERATORS exp[:operators] if exp.has_key?(:operators)
                xml.VALUES exp[:values] if exp.has_key?(:values)
                xml.TABLE_ID exp[:table_id] if exp.has_key?(:table_id)
                xml.LEFT_PARENS exp[:left_parens] if exp.has_key?(:left_parens)
                xml.RIGHT_PARENS exp[:right_parens] if exp.has_key?(:right_parens)
                xml.AND_OR exp[:and_or] if exp.has_key?(:and_or)
                if exp[:rt_expressions]
                  exp[:rt_expressions].each do |rt_exp|
                    xml.RT_EXPRESSION do
                      xml.TYPE rt_exp[:type] if rt_exp.has_key?(:type)
                      xml.COLUMN_NAME rt_exp[:column_name] if rt_exp.has_key?(:column_name)
                      xml.OPERATORS rt_exp[:operators] if rt_exp.has_key?(:operators)
                      xml.VALUES rt_exp[:values] if rt_exp.has_key?(:values)
                      xml.LEFT_PARENS rt_exp[:left_parens] if rt_exp.has_key?(:left_parens)
                      xml.RIGHT_PARENS rt_exp[:right_parens] if rt_exp.has_key?(:right_parens)
                      xml.AND_OR rt_exp[:and_or] if rt_exp.has_key?(:and_or)
                    end
                  end
                end
              end
            end
          end

          if options[:behavior]
            xml.BEHAVIOR do
              xml.OPTION_OPERATOR options[:behavior] if options.has_key?(:behavior)
              xml.TYPE_OPERATOR options[:type_operator] if options.has_key?(:type_operator)
              xml.MAILING_ID options[:mailing_id] if options.has_key?(:mailing_id)
              xml.REPORT_ID options[:report_id] if options.has_key?(:report_id)
              xml.LINK_NAME options[:link_name] if options.has_key?(:link_name)
              xml.WHERE_OPERATOR options[:where_operator] if options.has_key?(:where_operator)
              xml.CRITERIA_OPERATOR options[:criteria_operator] if options.has_key?(:criteria_operator)
              xml.VALUES options[:values] if options.has_key?(:values)
            end
          end
        end
      end
    end

    doc = send_xml_api_request(request_body)
    result_dom(doc)['ListId']
  end

  def create_query(options)
    raise ArgumentError, "Query name is not present" unless options[:query_name]
    raise ArgumentError, "Parent list id is not present" unless options[:parent_list_id]
    raise ArgumentError, "Criteria is required" unless options[:criteria]

    options[:visibility] ||= 0

    request_body = ''
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)
    xml.instruct!

    xml.Envelope do
      xml.Body do
        xml.CreateQuery do
          xml.QUERY_NAME options[:query_name]
          xml.PARENT_LIST_ID options[:parent_list_id]
          xml.VISIBILITY options[:visibility]

          xml.PARENT_FOLDER_ID options[:parent_folder_id] if options.has_key?(:parent_folder_id)
          xml.SELECT_COLUMNS options[:select_columns] if options.has_key?(:select_columns)
          xml.ALLOW_FIELD_CHANGE options[:allow_field_change] if options.has_key?(:allow_field_change)

          xml.CRITERIA do
            options[:criteria][:expressions].each do |exp|
              xml.EXPRESSION exp.slice(:criteria_type) do
                xml.COLUMN exp[:column] if exp.has_key?(:column)
                xml.OPERATOR exp[:operator] if exp.has_key?(:operator)
                xml.VALUE exp[:value] if exp.has_key?(:value)

                if exp.has_key?(:values)
                  xml.VALUES do
                    exp[:values].each do |value|
                      xml.VALUE value
                    end
                  end
                end

                xml.TIMEFRAME exp[:timeframe] if exp.has_key?(:timeframe)
                xml.TIME_UNIT exp[:time_unit] if exp.has_key?(:time_unit)
                xml.UNIT exp[:unit] if exp.has_key?(:unit)
                xml.PARENS exp[:parens] if exp.has_key?(:parens)
                xml.CONJUNCTION exp[:conjunction] if exp.key?(:conjunction)
              end
            end
          end
        end
      end
    end

    doc = send_xml_api_request(request_body)
    result_dom(doc)['ListId']
  end

  # Run query and calculate the number of contacts
  # Returns the job id if successfull
  #
  # === Options
  # :query_id
  #   The id of the query to be calculated
  # :email
  #   If specified, Engage sends a notiffication email
  #   when job is complete
  def calculate_query(options)
    raise ArgumentError, "Query Id must is required" unless options[:query_id]

    request_body = ''
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)
    xml.instruct!

    xml.Envelope do
      xml.Body do
        xml.CalculateQuery do
          xml.QUERY_ID options[:query_id]
          xml.EMAIL options[:email] if options.has_key?(:email)
        end
      end
    end

    doc = send_xml_api_request(request_body)
    result_dom(doc)['JOB_ID']
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
    result_dom(doc)['RecipientId'] rescue nil
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
    result_dom(doc)
  end

  # Update the column values of a lead in silverpop.
  #
  # expects a hash that contains: list_id, old_email.
  # additional values in the hash will be passed as column values,
  # with the key being the column name, and the value being the value.
  # Returns the Recipient Id.
  def update_contact(options={})
    contact_list_id = options.delete(:list_id)
    old_email = options.delete(:old_email)

    request_body = String.new
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)

    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.UpdateRecipient do
          xml.LIST_ID contact_list_id
          xml.OLD_EMAIL old_email

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
    result_dom(doc)['RecipientId']
  end

  # Moves a contact in a database to an opted-out state.
  #
  # :list_id
  #   Identifies the ID of the database from which to opt out the contact.
  # :email
  #   The contact email address to opt out. Note: If using a regular email
  #   key database, a node must exist for the Email column.If passing
  #   MAILING_ID, RECIPIENT_ID, and JOB_ID, Engage does not require EMAIL.
  #   You must provide each of the three elements if EMAIL is not included.
  def opt_out_contact(options={})
    contact_list_id = options.delete(:list_id)
    email = options.delete(:email)

    request_body = String.new
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)

    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.OptOutRecipient do
          xml.LIST_ID contact_list_id
          xml.EMAIL email

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
    result_dom(doc)['RecipientId']
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
    result_dom(doc)['MAILING_ID']
  end

  # Extracts a listing of mailings sent for an organization for a
  # specified date range.
  #
  # === Options
  # See the Silverpop XML API documentation,
  # chapter "Get a List of Sent Mailings for an Org".
  def get_sent_mailings_for_org(options={})
    raise ArgumentError, ":date_start is required" unless options.has_key?(:date_start)
    raise ArgumentError, ":date_end is required" unless options.has_key?(:date_end)

    options[:date_start] =
      options[:date_start].utc.strftime("%m/%d/%Y %H:%M:%S") unless options[:date_start].is_a?(String)
    options[:date_end] =
      options[:date_end].utc.strftime("%m/%d/%Y %H:%M:%S") unless options[:date_end].is_a?(String)

    request_body = String.new
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)

    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.GetSentMailingsForOrg do
          apply_xml_options!(xml, options)
        end
      end
    end

    doc = send_xml_api_request(request_body)
    result_dom(doc)["Mailing"] || []
  end

  # This interface allows exporting unique contact-level events and
  # creates a .zip file containing a single flat file with all metrics.
  # You can request all (or a subset) of the Event Types.
  #
  # === Options
  # See the Silverpop XML API documentation,
  # chapter "Export Raw Contact Events".
  def raw_recipient_data_export(options={})
    request_body = String.new
    xml = Builder::XmlMarkup.new(:target => request_body, :indent => 1)

    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.RawRecipientDataExport do
          apply_xml_options!(xml, options)
        end
      end
    end

    doc = send_xml_api_request(request_body)
    result_dom(doc)
  end

  protected

  # Given a silverpop api response document, was the api call successful?
  def silverpop_successful?(doc)
    %w[true success].include?(result_dom(doc)['SUCCESS'].downcase) rescue false
  end

  # Given a silverpop api response document, parse out the result
  def result_dom(doc)
    doc['Envelope']['Body']['RESULT']
  end

  # Execute an xml api request, and parse the response
  # Given a parsed xml response document for the silverpop api call
  def send_xml_api_request(markup)
    result = send_oauth_request(markup, "#{self.api_url}/XMLAPI", 'api')
    doc = Hash.from_xml(REXML::Document.new(result).to_s)

    return doc if silverpop_successful?(doc)

    raise_error(doc)
  end

  def raise_error(doc)
    fault = doc['Envelope']['Body']['Fault'] rescue nil
    err_id = fault['detail']['error']['errorid'].to_i rescue nil

    raise "Operation failed" if not fault or not err_id

    msg = "#{fault['FaultString']} (Error ID: #{err_id})"

    case err_id
      when 121
        raise Silverpopper::EmailBlockedError.new(msg, err_id)
      when 126
        raise Silverpopper::EmailNotInListError.new(msg, err_id)
      else
        raise Silverpopper::SilverpopError.new(msg, err_id)
    end
  end

  # A helper method for setting the session_id when logging in
  def session_id=(session_id)
    @session_id = session_id.blank? ? nil : ";jsessionid=#{session_id}"
  end

  def access_token=(access_token)
    @access_token = access_token.blank? ? nil : "#{access_token}"
  end
end
