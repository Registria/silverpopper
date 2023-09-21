# The silverpop client to initialize and make XMLAPI or Transact API requests
# through.  Handles authentication, and many silverpop commands.
class Silverpopper::Client
  include Silverpopper::TransferApi
  include Silverpopper::TransactApi
  include Silverpopper::XmlApi
  include Silverpopper::Common

  POD_API_URLS = {
    "1" => "api-campaign-us-1.goacoustic.com",
    "2" => "api-campaign-us-2.goacoustic.com",
    "3" => "api-campaign-us-3.goacoustic.com",
    "4" => "api-campaign-us-4.goacoustic.com",
    "5" => "api-campaign-us-5.goacoustic.com",
    "6" => "api-campaign-eu-1.goacoustic.com",
    "7" => "api-campaign-ap-2.goacoustic.com",
    "8" => "api-campaign-ca-1.goacoustic.com",
    "9" => "api-campaign-us-6.goacoustic.com",
    "A" => "api-campaign-ap-1.goacoustic.com",
    "B" => "api-campaign-ap-3.goacoustic.com",
    "PILOT" => "api-campaign-pilot.goacoustic.com"
  }.freeze

  # User names to log into silverpop with
  attr_reader :api_username, :client_id, :ftp_username

  # pod to use, this should be a number and is used to build the url
  # to make api calls to
  attr_reader :pod

  # Silverpop urls
  attr_reader :api_url, :transact_url, :transfer_url, :oauth_url

  # Silverpop FTP client
  attr_reader :ftp

  # Login Type
  attr_reader :login_type

  # Cached remote contact lists
  attr_accessor :cached_lists

  # Initialize a Silverpopper Client
  #
  # expects a hash with string keys: 'api_username', 'api_password', 'pod'.
  # pod argument is defaulted to 1
  def initialize(options={})
    @api_username = options[:api_username]
    @api_password = options[:api_password]
    @client_id = options[:client_id]
    @client_secret = options[:client_secret]
    @refresh_token = options[:refresh_token]
    @ftp_username = options[:ftp_username] || options[:api_username]
    @ftp_password = options[:ftp_password] || options[:api_password]
    @pod = options[:pod] || 1
    @api_url = options[:api_url] || "http://api#{@pod}.silverpop.com"
    @transact_url = options[:transact_url] || "http://transact#{@pod}.silverpop.com"
    @transfer_url = options[:transfer_url] || "transfer#{@pod}.silverpop.com"
    @oauth_url = options[:oauth_url] || "https://#{POD_API_URLS[@pod.to_s]}/oauth/token"
    @ftp = Net::FTP.new
    @cached_lists = []
    @login_type = options[:login_type] || "oauth"
  end

  protected
  # Passwords to use to log into silverpop with
  attr_reader :api_password, :client_secret, :ftp_password, :refresh_token
end
