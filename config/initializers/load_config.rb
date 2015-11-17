require 'yaml'
# Read config files and store applicable values in APP_CONFIG constant
main_config = YAML.load_file("#{Rails.root}/config/config.yml")
if Rails.env == 'test'
  secret_config = YAML.load_file("#{Rails.root}/config/config_secret.test.yml")
else
  secret_config = YAML.load_file("#{Rails.root}/config/config_secret.yml")
end
APP_CONFIG = main_config.merge(secret_config)
