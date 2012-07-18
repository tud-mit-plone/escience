#!/bin/bash

gem install bundler 
bundle install 
rake generate_secret_token

cp ./config/database.yml.example ./config/database.ym

