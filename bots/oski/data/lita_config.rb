require '/lita/lita-cmdb.rb'

Lita.configure do |config|
  config.robot.name = "Oski D. Bot"
  config.robot.mention_name = "oski"
  config.robot.alias = "."
  config.robot.log_level = :info
  config.robot.adapter = :slack
  config.robot.admins = ENV['LITA_ADMINS'].split(',')
  config.adapters.slack.token = "#{ENV['LITA_SLACK_TOKEN']}"
  config.redis[:host] = "#{ENV['LITA_REDIS_HOST']}"
  config.handlers.dig.default_resolver = '127.0.0.1'

  config.handlers.cmdb.itop_rest_endpoint = "#{ENV['LITA_ITOP_REST_ENDPOINT']}"
  config.handlers.cmdb.itop_user = "#{ENV['LITA_ITOP_USER']}"
  config.handlers.cmdb.itop_pass = "#{ENV['LITA_ITOP_PASS']}"
end
