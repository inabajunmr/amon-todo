# amon-todo

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
$ curl -X POST --data-urlencode 'username=init' --data-urlencode 'password=pswd' --data-urlencode 'grant_type=password' localhost:5000/oauth/token
```

`init` user is created by sql/sqlite.sql.

### User

List users.

```
$ curl localhost:5000/user
```

Post new user.

```
$ curl -X POST -H "Content-Type: application/json" -d '{"username":"inaba", "password":"pswd"}' localhost:5000/user
```

Delete user.

```
$ curl -X DELETE -H localhost:5000/user/inaba
```
