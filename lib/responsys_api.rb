require "i18n"
require "connection_pool"
require "savon"

I18n.load_path.concat Dir.glob( File.dirname(__FILE__) + "/responsys/i18n/*.yml" )

require "responsys/exceptions"
require "responsys/helper"
require "responsys/configuration"
require "responsys/api/all"
require "responsys/api/object/all"
require "responsys/api/session_pool"
require "responsys/api/session"
require "responsys/api/client"
require "responsys/member"