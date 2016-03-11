TsbProjectData::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  config.assets.js_compressor = :uglifier

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true # TODO - change this??

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify


  # ENVIRONMENT VARS
  ###################

  # these are expected to be linked dockers.
  MEMCACHED_HOST =         "docker-host:11211"
  FUSEKI_HOST =            "http://docker-host:3030" 
  ELASTICSEARCH_HOST =     "http://docker-host:9200"

  SPARQL_ENDPOINT =        "#{FUSEKI_HOST}/innovateuk/sparql"
  UPDATE_ENDPOINT =        "#{FUSEKI_HOST}/innovateuk/update"
  DATA_ENDPOINT =          "#{FUSEKI_HOST}/innovateuk/data"

  ENV['ELASTICSEARCH_URL'] = ELASTICSEARCH_HOST

  config.cache_store = :dalli_store, MEMCACHED_HOST

  PublishMyData.configure do |config|
    config.sparql_endpoint = SPARQL_ENDPOINT
    config.local_domain = 'tsb-projects.labs.theodi.org'
    config.tripod_cache_store = Tripod::CacheStores::MemcachedCacheStore.new(MEMCACHED_HOST) #nil
    config.sparql_timeout_seconds = 7
  end

  TsbProjectData::DATA_ENDPOINT = DATA_ENDPOINT

  # TODO: we'll need to do something so this doesn't get stomped / deleted when we redeploy.
  # (see start-server-production.sh)
  TsbProjectData::DUMP_OUTPUT_PATH = File.join(Rails.root, 'public', 'dumps')

  Tripod.configure do |config|
    config.update_endpoint = UPDATE_ENDPOINT
  end
end


