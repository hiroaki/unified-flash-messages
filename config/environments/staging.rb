# Use the production environment settings as a base
# and override only the staging environment-specific settings.
require_relative "production"

Rails.application.configure do
  config.log_level = :debug
end
