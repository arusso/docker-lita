FROM ubuntu:xenial

MAINTAINER Aaron Russo <arusso@berkeley.edu>

# Install our prerequisites
RUN apt-get update -y \
    && apt-get install -y ruby ruby-dev make gcc g++ libssl-dev libpcap-dev \
    && gem install lita --no-ri --no-rdoc \
    && lita new
COPY data/Gemfile /lita/Gemfile
RUN cd /lita && bundle

# Get rid of things we no longer need
RUN apt-get remove -y gcc g++ libssl-dev libpcap-dev ruby-dev \
    && apt-get clean \
    && rm -rf /tmp/*

# Copy configuration and entrypoint
COPY data/start-lita.sh /lita/start-lita.sh
RUN chmod +x /lita/start-lita.sh
COPY data/lita_config.rb /lita/lita_config.rb
COPY data/lita-tickets.rb /lita/lita-tickets.rb

ENTRYPOINT [ "/lita/start-lita.sh" ]
