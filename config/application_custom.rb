module Consul
  class Application < Rails::Application
    config.time_zone = 'London'
    config.i18n.default_locale = :en
  end
end
