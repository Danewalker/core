Ophal installation instructions
===============================

This document is just a brief. For a comprenhensive installation guide please
refer to the online Ophal manual: http://ophal.org/manual.


## I. Server configuration
This instructions assume that you installed Ophal at /var/www/ophal.

Ophal can run on native Nginx's HttpLuaModule or as a humble CGI script on
Apache, Lighttpd and others that support CGI and URL rewriting. FastCGI support
can be implemented with a FastCGI wrapper on Apache, Nginx, Lighttpd and several
other web servers.

### Apache
Enable mod_rewrite and mod_cgi, then use following configuration for reference:

#### Sub-directory

    Alias /lua /var/www/ophal/
    <Directory "/var/www/ophal">
      AllowOverride All
      Options Indexes FollowSymLinks MultiViews +ExecCGI
      Order allow,deny
      Allow from all
    </Directory>

#### Virtualhost

    <VirtualHost *:80>
      ServerAlias ophal

      DocumentRoot /var/www/ophal
      <Directory />
        Options FollowSymLinks
        AllowOverride None
      </Directory>
      <Directory /var/www/ophal/>
        Options Indexes FollowSymLinks MultiViews +ExecCGI
        AllowOverride All
        Order allow,deny
        allow from all
      </Directory>

      ErrorLog /var/log/apache2/ophal-error.log

      # Possible values include: debug, info, notice, warn, error, crit,
      # alert, emerg.
      LogLevel debug

      CustomLog /var/log/apache2/ophal-access.log combined
    </VirtualHost>

### Lighttpd
Install mod_magnet and use the file lighttpd.ophal.lua to configure your
server. Also, enable module cgi. Then use following configuration for reference:

    $HTTP["host"] =~ ".+\.ophal" {
      evhost.path-pattern = "/var/www/%_/"
      index-file.names = ("index.cgi")
      cgi.assign = ( ".cgi" => "/usr/local/bin/luajit" )
      magnet.attract-physical-path-to = ("/etc/lighttpd/lighttpd.ophal.lua")
    }

Notice that configuration above assumes that you are using "luajit".

### Nginx
Install HttpLuaModule and use the file nginx.ophal.conf to configure your server.
Make sure to set 'server_name' and 'root' correctly.


## II. Dependencies

### LuaJIT or Lua?
Ophal uses Lua 5.1 by default, but is compatible with LuaJIT 2.x if you prefer it.
You need to edit the first line of index.cgi in order to switch interpreter.

### Debian

```sh
$ sudo luarocks install lpeg
$ sudo apt-get install uuid-dev
$ sudo luarocks install luuid
$ sudo luarocks install luafilesystem
$ sudo luarocks install luasocket
$ cd /tmp
$ git clone --depth=1 git://github.com/ophal/seawolf.git
$ sudo mv seawolf /usr/local/share/lua/5.1/
```


## III. Installation wizard

Open your Ophal installation in a web browser, you should be redirected to the Installation
Wizard, follow the instructions. The wizard will check dependencies and ask for configuration
parameters, then will generate a settings.lua for you, copy the text, store as settings.lua
into the same directory of index.cgi, make the desired changes an set it to read-only.


### (Optional) Configure the Content module
Run the following SQL queries in strict order:

```SQL
CREATE TABLE content(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id UNSIGNED BIG INT, language VARCHAR(12), title VARCHAR(255), teaser TEXT, body TEXT, created UNSIGNED BIG INT, changed UNSIGNED BIG INT, status BOOLEAN, sticky BOOLEAN, comment BOOLEAN, promote BOOLEAN);
CREATE INDEX idx_content_created ON content (created DESC);
CREATE INDEX idx_content_changed ON content (changed DESC);
CREATE INDEX idx_content_frontpage ON content (promote, status, sticky, created DESC);
CREATE INDEX idx_content_title ON content (title);
CREATE INDEX idx_content_user ON content (user_id);
```

Add the following to settings.lua:

```Lua
settings.content = {
  entities = {},
  items_per_page = 10, -- default: 10
}
```

Also, make sure to enable and configure the User module.

NOTE: Ophal is compatible with SQLite only.

### (Optional) Configure the Comment module

Run the following SQL queries in strict order:

```SQL
CREATE TABLE comment(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_id UNSIGNED BIG INT, -- Entity associated with this object
  parent_id UNSIGNED BIG INT, -- Parent object
  user_id UNSIGNED BIG INT, -- User ID of author
  language VARCHAR(12), -- Language code
  body TEXT, -- Comment body
  created UNSIGNED BIG INT, -- Creation date
  changed UNSIGNED BIG INT, -- Last change date
  status BOOLEAN,
  sticky BOOLEAN
);
CREATE INDEX idx_comment_created ON comment (created DESC);
CREATE INDEX idx_comment_changed ON comment (changed DESC);
CREATE INDEX idx_comment_linear ON comment (entity_id, status);
CREATE INDEX idx_comment_linear_sticky ON comment (entity_id, status, sticky);
CREATE INDEX idx_comment_full_linear ON comment (entity_id);
CREATE INDEX idx_comment_full_linear_sticky ON comment (entity_id, sticky);
CREATE INDEX idx_comment_tree ON comment (parent_id, status);
CREATE INDEX idx_comment_tree_sticky ON comment (parent_id, status, sticky);
CREATE INDEX idx_comment_full_tree ON comment (parent_id);
CREATE INDEX idx_comment_full_tree_sticky ON comment (parent_id, sticky);
CREATE INDEX idx_comment_user ON comment (user_id);
```

Add the following to settings.lua:

```Lua
settings.comment = {
  entities = {
    content = true,
  },
}
```

Also, make sure to enable and<Virtual configure the User module.

NOTE: Ophal is compatible with SQLite only.

### (Optional) Configure the User module
WARNING! Since the user module allows to start an authenticated session, meaning
that certain users will have access to priviledged data, the use of an SSL
certificated and HTTPS is strongly recommended. Please make sure that your
production server running an Ophal site (with user module enable) is
correctly configured for secure connections.

Run the following SQL queries in strict order:

1. Create schema:

  ```SQL
  CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(255), mail VARCHAR(255), pass VARCHAR(255), active BOOLEAN, created UNSIGNED BIG INT);
  CREATE UNIQUE INDEX unq_idx_user_name ON users (name);
  CREATE INDEX idx_user_created ON users (created);
  CREATE INDEX idx_user_mail ON users (mail);

  CREATE TABLE role(id VARCHAR(255) PRIMARY KEY, name VARCHAR(255), active BOOLEAN, weight INT);
  CREATE UNIQUE INDEX unq_idx_role_name ON role (name);
  CREATE INDEX idx_role_weight ON role (weight);

  CREATE TABLE user_role(user_id UNSIGNED BIG INT, role_id VARCHAR(255), PRIMARY KEY (user_id, role_id));

  CREATE TABLE role_permission(role_id VARCHAR(255), permission VARCHAR(255), module VARCHAR(255), PRIMARY KEY (role_id, permission));
  CREATE INDEX idx_role_permission_perm ON role_permission (permission);
  ```

  NOTE: Ophal is compatible with SQLite only.

2. Generate a password for superuser with following script (requires ophal-cli):

  ```sh
  $ ophal sha256 mypassword
  89e01536ac207279409d4de1e5253e01f4a1769e696db0d6062ca9b8f56767c8
  ```

  Alternatively, you can run the following lua code:

  ```sh
  > print(require 'lsha2'.hash256 'mypassword')
  89e01536ac207279409d4de1e5253e01f4a1769e696db0d6062ca9b8f56767c8
  ```

  NOTICE: this script outputs a password hash, change 'mypassword' by 'yourpass'

3. Create user 1:

  ```SQL
  INSERT INTO users VALUES(1, 'root', 'test@example.com', 'your password hash', 1, strftime('%s', 'now'));
  ```

4. Enable Form API:

  ```Lua
  settings.formapi = true
  ```

5. Enable this module:

  ```Lua
  settings.modules.user = true
  ```

6. Configure default roles

  You can either add the following to your settings.lua

  ```Lua
  --[[
    User module options
  ]]
  settings.user = {
    entities = {
      content = true,
    },
    permissions_storage = true,
    -- algorithm = 'sha256', -- Be careful!
    role = {
      anonymous = {
        'access content',
      },
      authenticated = {
        'access content',
        'create content',
        'edit own content',
      },
    }
  }
  ```

  Or run the following SQL queries:

  ```SQL
  INSERT INTO role_permission VALUES('anonymous', 'access content', 'user');
  INSERT INTO role_permission VALUES('authenticated', 'access content', 'user');
  INSERT INTO role_permission VALUES('authenticated', 'create content', 'user');
  INSERT INTO role_permission VALUES('authenticated', 'edit own content', 'user');
  ```

### (Optional) Configure the Tag module
Run the following SQL queries in strict order:

```SQL
CREATE TABLE field_tag(entity_type VARCHAR(255), entity_id BIG INT, tag_id BIG INT, PRIMARY KEY (entity_type, entity_id, tag_id));
CREATE TABLE tag(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id BIG INT,
  name VARCHAR(255),
  language VARCHAR(12), -- Language code
  description TEXT, -- Tag description
  created UNSIGNED BIG INT, -- Creation date
  changed UNSIGNED BIG INT, -- Last change date
  status BOOLEAN
);
CREATE UNIQUE INDEX unq_idx_tag_name ON tag (name);
CREATE INDEX idx_tag_user ON tag (user_id);
CREATE INDEX idx_tag_created ON tag (created DESC);
CREATE INDEX idx_tag_changed ON tag (changed DESC);
```

Add the following to settings.lua:

```Lua
settings.tag = {
  entities = {
    content = true,
  },
  items_per_page = 10, -- default: 10
}
```

Also, make sure to enable and configure the Content module.

### (Optional) Configure the route aliases database storage
Complementary to the use of route_register_alias(), you can store route aliases
into the database. This is specially useful for sites that make extensive use of
semantic urls (i.e: /my-rocking-article instead of /content/7).

1. Run the following SQL queries in strict order:

  ```SQL
  CREATE TABLE route_alias(id INTEGER PRIMARY KEY AUTOINCREMENT, source VARCHAR(255), alias VARCHAR(255), language VARCHAR(12));
  CREATE INDEX idx_route_alias_alias_language_id ON route_alias (alias, language, id);
  CREATE INDEX idx_route_alias_source_language_id ON route_alias (source, language, id);
  ```

2. Enable database storage for route aliases

  ```Lua
  --[[
    Route aliases database storage
  ]]f
  settings.route_aliases_storage = true
  ```

### (Optional) Configure the files metadata database storage
Complementary to the use of file module, you can store files metadata
into the database.

1. Run the following SQL queries in strict order:

  ```SQL
  CREATE TABLE file(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id UNSIGNED BIG INT, -- User ID of author
    filename VARCHAR(255),
    filepath VARCHAR(255),
    filemime VARCHAR(255),
    filesize UNSIGNED INT(10),
    status boolean,
    timestamp UNSIGNED BIG INT
  );
  CREATE INDEX idx_file_user ON file (user_id);
  CREATE INDEX idx_file_status ON file (status);
  CREATE INDEX idx_file_timestamp ON file (timestamp);
  ```

2. Enable database storage for route aliases

  ```Lua
  --[[
    Files metadata database storage
  ]]
  settings.filedb_storage = true
  settings.bytes_per_chunk = 1024 * 1024,
  ```

  NOTE: Ophal is compatible with SQLite only.

3. Send feedback

  Whether you successfully installed Ophal or not, please file an issue with your
  feedback at https://github.com/ophal/core/issues/new in order to help us improve
  the installation instructions and the installer.


-- The Ophal Team

