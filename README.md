## Getting Started

Ensure your bot has an environment file defined for the environment you want to launch. You should at least populate the dev environment file (bots/<bot>/env/dev).

Launching your bot with the included scripts will ensure the bot restarts on failure, and is properly linked to a redis container as needed by lita:

    ./bot-launch.sh <bot> <env>
    ./bot-launch.sh oski dev

You can kill your bot (and all data/logs/etc) by running:

    ./bot-kill.sh <bot> <env>
    ./bot-kill.sh oski dev

If you're developing code, you often need to rebuild the docker image and relaunch your containers. You can use our helper script to do all that for you:

    ./bot-rebuild-and-relaunch.sh <bot> <env>
    ./bot-rebuild-and-relaunch.sh oski dev

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
