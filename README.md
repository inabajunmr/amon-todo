# amon-todo

amon-todo is sample API server for todo application.

## Init

Initialize database for local develoment.

```
$ sqlite3 db/development.db < sql/sqlite.sql
```

## Run

```
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
$ curl -H "Authorization:Bearer C77609E8-B97D-11EC-9728-94BE6C8D9CDA" localhost:5000/user
```

Post new user.

```
$ curl -H "Authorization:Bearer XXX" -X POST -H "Content-Type: application/json" -d '{"username":"inaba", "password":"pswd"}' localhost:5000/user
```

Delete user.

```
$ curl -H "Authorization:Bearer XXX" -X DELETE -H localhost:5000/user/inaba
```
