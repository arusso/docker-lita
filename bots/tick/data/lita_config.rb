require '/lita/lita-tickets.rb'

Lita.configure do |config|
  config.robot.name = "Tick(et) Bot"
  config.robot.mention_name = "tickbot"
  config.robot.alias = "!tick"
  config.robot.log_level = :info
  config.robot.adapter = :slack
  config.robot.admins = ENV['LITA_ADMINS'].split(',')
  config.adapters.slack.token = "#{ENV['LITA_SLACK_TOKEN']}"
  config.redis[:host] = "#{ENV['LITA_REDIS_HOST']}"
end
