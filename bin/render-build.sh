#!/usr/bin/env bash
# exit on error
set -o errexit

echo "deb http://pub-repo.sematext.com/ubuntu sematext main" | tee /etc/apt/sources.list.d/sematext.list > /dev/null
wget -O - https://pub-repo.sematext.com/ubuntu/sematext.gpg.key | apt-key add -
apt-get -y update
apt-get -y install sematext-agent

bash /opt/spm/bin/setup-infra \
    --infra-token 00cc46cd-a1ad-444c-a07d-13295e49fd79

yarn install --frozen-lockfile
BUNDLE_WITHOUT='development:test' BUNDLE_DEPLOYMENT=1 bundle install -j4
bundle exec rake assets:precompile
bundle exec rake assets:clean
./release-tasks.sh
