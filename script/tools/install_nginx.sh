#!/bin/bash

sudo echo "deb http://nginx.org/packages/ubuntu/ precise nginx" >> /etc/apt/sources.list
sudo echo "deb-src http://nginx.org/packages/ubuntu/ precise nginx" >> /etc/apt/sources.list.

sudo apt-get update
sudo apt-get install nginx

