# Provides an interface to transfer files to silverpop
module Silverpopper::TransferApi
  # Authenticate on the ftp server
  def ftp_login
    return true if self.ftp.status.scan(/Logged\sin\sas/).any? rescue nil

    self.ftp.connect(self.transfer_url)
    self.ftp.login(self.ftp_username, self.ftp_password)
  end

  # Close the ftp connection
  def ftp_logout
    self.ftp.close
  end

  # Clean up the given ftp directory
  def ftp_cleanup(dir)
    raise ArgumentError, "expected to get some directory to cleanup" unless dir.present?

    self.ftp.chdir(dir)
    raise RuntimeError, "unable to enter the given directory #{dir}" unless self.ftp.pwd == dir

    self.ftp.nlst.each { |f| self.ftp.delete(f) }
    true
  end

  # Transfer a list to silverpop
  # Expects to get source file and mapping hash
  #
  # === Options
  # :map
  #   :action
  #     Type of import you are performed
  #   :list_type
  #     Type of the database (only needed if action is CREATE)
  #     0 – Database
  #     6 – Seed list
  #     13 – Suppression list
  #   :list_name
  #     Defines the name of the new database (if action is CREATE)
  #   :list_id
  #     Unique ID of the database in the Engage system (except CREATE)
  #   [:list_visibility]
  #     Defines the visibility of the newly created database
  #     0 – private
  #     1 – shared
  #   [:parent_folder_path]
  #     Used with CREATE action to specify the folder to place the DB in
  #   :file_type
  #     Format of the source file
  #     0 – CSV file
  #     1 – Tab-separated file
  #     2 – Pipe-separated file
  #   [:hasheaders]
  #     If the first line in the source file contains column definitions
  #   [:list_date_format]
  #   [:double_opt_in]
  #   [:encoded_as_md5]
  #   [:sync_fields]
  #     Expects to be an array of hashes
  #     :name
  #   :columns
  #     Expects to be an array of hashes (if ACTION is CREATE)
  #     :name, :type, :is_required, :key_column, :default_value
  #   :mapping
  #     Expects to be an array of hashes
  #     :index, :name, [:include]
  #   [:contact_lists]
  #     Expects to be an array of hashes. Export contacts also to
  #     given contact lists
  #     :contact_list_id
  # :data
  #   A source to export (could be in any format)
  # :name
  #   The name for the file which will be stored on the ftp
  #   (map file will be stored under the same name with .map.xml suffix)
  def transfer_lists(sources)
    sources.each do |source|
      map = source[:map]
      data = source[:data]
      name = source[:name]

      transfer_list(map, data, name)
    end

    true
  end

  protected

  def transfer_list(map, data, name)
    raise ArgumentError if not map or not data or not name

    map = make_map(map)

    stor_file(data, name)
    stor_file(map, "#{name}.map.xml")

    true
  end

  # Stream the given source to the ftp
  def stor_file(source, filename)
    source = source.read if source.respond_to?(:read)

    self.ftp.chdir("/upload")
    self.ftp.storbinary("STOR " + filename, StringIO.new(source), Net::FTP::DEFAULT_BLOCKSIZE)

    true
  end

  # Create a map source from the given hash
  def make_map(map)
    raise ArgumentError, "map should be a hash" unless map.is_a?(Hash)

    map_body = ''
    xml = Builder::XmlMarkup.new(:target => map_body, :indent => 1)

    xml.instruct!
    xml.Envelope do
      xml.Body do
        xml.LIST_IMPORT do
          xml.LIST_INFO do
            xml.ACTION map[:action] if map[:action].present?
            xml.LIST_TYPE map[:list_type] if map[:list_type].present?
            xml.LIST_NAME map[:list_name] if map[:list_name].present?
            xml.LIST_ID map[:list_id] if map[:list_id].present?
            xml.LIST_VISIBILITY map[:list_visibility] if map[:list_visibility].present?
            xml.LIST_DATE_FORMAT map[:list_date_format] if map[:list_date_format].present?
            xml.FILE_TYPE map[:file_type] if map[:file_type].present?
            xml.PARENT_FOLDER_PATH map[:parent_folder_path] if map[:parent_folder_path].present?
            xml.HASHEADERS !!map[:hasheaders] if map[:hasheaders].to_s.present?
            xml.DOUBLE_OPT_IN !!map[:double_opt_in] if map[:double_opt_in].to_s.present?
            xml.ENCODED_AS_MD5 !!map[:encoded_as_md5] if map[:encoded_as_md5].to_s.present?

            if map[:sync_fields].present?
              xml.SYNC_FIELDS do
                map[:sync_fields].each do |sync_field|
                  xml.SYNC_FIELD do
                    xml.NAME sync_field[:name]
                  end
                end
              end
            end
          end

          if map[:columns].present?
            xml.COLUMNS do
              map[:columns].each do |column|
                xml.COLUMN do
                  xml.NAME column[:name] if column[:name].present?
                  xml.TYPE column[:type] if column[:type].present?
                  xml.IS_REQUIRED !!column[:is_required] if column[:is_required].to_s.present?
                  xml.KEY_COLUMN column[:key_column] if column[:key_column].present?
                  xml.DEFAULT_VALUE column[:default_value] if column[:default_value].present?
                end
              end
            end
          end

          if map[:mapping].present?
            xml.MAPPING do
              map[:mapping].each do |m|
                xml.COLUMN do
                  xml.INDEX m[:index] if m[:index].present?
                  xml.NAME m[:name] if m[:name].present?
                  xml.INCLUDE !!m[:include] if m[:include].to_s.present?
                end
              end
            end
          end

          if map[:contact_lists].present?
            xml.CONTACT_LISTS do
              map[:contact_lists].each do |list|
                xml.CONTACT_LIST_ID list[:contact_list_id] if list[:contact_list_id].present?
              end
            end
          end
        end
      end
    end

    map_body
  end
end
