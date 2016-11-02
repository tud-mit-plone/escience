# eScience

The platform offers a virtual room to communicate with other researchers, to gain new insights together and to develop and share resources for the purpose of research.

# Installation

## Dependencies

To install the eScience platform, first make sure to install its dependencies.

### Ruby

eScience requires **Ruby 2.1.1**. It is recommended to install it using [RVM](https://rvm.io):

```
gpg2 --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
curl -L get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm requirements
rvm install 2.1.1
```

### Database

For development setups the recommended database system is **[SQLite](https://www.sqlite.org/)**, for production deployment install **[MySQL](https://www.mysql.de/)**. On Debian, the package names are `libsqlite3-dev` or `mysql-server libmysqlclient-dev`, respectively.

### Other

For image processing needs, eScience requires several other libraries and their development headers. On Debian the libraries are packaged in `imagemagick libpng-dev libjpeg-dev libmagickwand-dev graphicsmagick`.

## Installation

First initialize the Ruby environment:

```
rvm 2.1.1
```

Now install a few Gems required for the installation process:

```
gem install bundler rails rake
```

Then it's time to get a copy of the source code:

```
git clone https://github.com/tud-mit-plone/escience.git
```

Change to the new source directory:

```
cd escience
```

From there, initiate the installation process:

```
bundle install
bundle exec rake generate_secret_token
```

## Database Setup

Copy the database configuration template to the correct location:

```
cp config/database.yml.example config/database.yml
```

Customize the resulting file to your needs. For a development setup use something like:

```YAML
development:
  adapter: sqlite3
  database: redmine_development
  host: localhost
  username: root
  password: ""
  encoding: utf8
````

In a production deployment supply the login data for the MySQL database to use:

```YAML
production:
  adapter: mysql2
  database: escience
  host: localhost
  username: escience
  password: secret
  encoding: utf8
```

Finally, create the database structure and fill the database with initial data. Make sure to run the command against the correct environment. Replace `RAILS_ENV="development"` with `RAILS_ENV="production"` for a production deployment.

```
rake db:migrate RAILS_ENV="development"
rake db:migrate_plugins RAILS_ENV="development"
rake db:seed RAILS_ENV="development"
```

# Launching

To launch the rails development server, execute:

```
rails server -e development
```

This launches a local HTTP server. Visit [http://localhost:3000](http://localhost:3000) to see the platform in action.

# Credits
The eScience platform is based on [Redmine](http://redmine.org).
