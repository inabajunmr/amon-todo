# amon-todo

amon-todo is sample API server for todo application.

## Install library

```
$ caton install
```

### For my environment(M1 Mac Bigsur)

Before `carton install`.

```
PATH="$(brew --prefix mysql-client)/bin:$PATH"
export LIBRARY_PATH=$(brew --prefix openssl)/lib:$LIBRARY_PATH
$ brew install mysql
$ mysql
mysql > create user 'inabajun'@'localhost' identified  by 's3kr1t';
mysql > grant all privileges on test.* to 'inabajun'@'localhost';
$ brew install zstd
$ export LIBRARY_PATH=$(brew --prefix zstd)/lib:$LIBRARY_PATH
```

## With SQLite

### Init

Initialize database for local develoment.

```
$ sqlite3 db/development.db < sql/sqlite.sql
```

### Run

```
$ carton exec -- plackup -Ilib -R ./lib --access-log /dev/null -p 5000 -a ./script/amon-todo-server
```

## With MySQL

### Init

Run MySQL.

```
$ mysql.server # or using docker
$ mysql -uroot
mysql > create database amontodo
```

and create tables by `sql/mysql.sql`.

### Run

```
$ export PLACK_ENV="production"
$ export DATABASE_USERNAME="root"
$ export DATABASE_SECRET=""
$ export DATABASE_HOST="localhost"
$ carton exec -- plackup -Ilib -R ./lib --access-log /dev/null -p 5000 -a ./script/amon-todo-server
```

## API

### Authentication

Using bearer access token.

Issue access token.

```
$ curl -X POST --data-urlencode 'username=init' --data-urlencode 'password=password' --data-urlencode 'grant_type=password' localhost:5000/oauth/token
```
 
`init` user is created by sql/sqlite.sql.

### User

List users.

```
$ curl -H "Authorization:Bearer XXX" localhost:5000/user
```

Post new user.

```
$ curl -H "Authorization:Bearer XXX" -X POST -H "Content-Type: application/json" -d '{"username":"inaba", "password":"pswd"}' localhost:5000/user
```

Delete user.

```
$ curl -H "Authorization:Bearer XXX" -X DELETE -H localhost:5000/user/inaba
```

### Todo

Todo belongs to specific user.
This relationship is binded by access token.

List todos.

```
$ curl -H "Authorization:Bearer XXX" -X GET localhost:5000/todo
```

Post new todo.

```
$ curl -H "Authorization:Bearer XXX" -X POST -H "Content-Type: application/json" -d '{"todo":"learning perl"}' localhost:5000/todo
```

Delete todo.

```
$ curl -H "Authorization:Bearer XXX" -X DELETE localhost:5000/todo/XXX
```
