## Getting Started

Ensure your bot has an environment file defined for the environment you want to launch. You should at least populate the dev environment file (bots/<bot>/env/dev).

Launch your bot like so:

    ./bot-launch.sh <bot> <env>
    ./bot-launch.sh oski dev

## Bot - Oski

`oski` is the general purpose bot and currently handles looking up contacts and slas for services we provide.

You must provide the following environment variables in an oski environment file:

    LITA_SLACK_TOKEN=your-slack-token
    # you probably shouldn't change this
    LITA_REDIS_HOST=redis
    LITA_ITOP_REST_ENDPOINT=https://your.itop.server.com/edu/itop/webservices/rest.php
    LITA_ITOP_USER=itop-service-account
    LITA_ITOP_PASSWORD=itop-service-account-password

## Bot - Tick

`tick` is our ticketing bot and is currently under development.

You must provide the following environment variables in a tick environment file:

    LITA_SLACK_TOKEN=your-slack-token
    # you probably shouldn't change this
    LITA_REDIS_HOST=redis
