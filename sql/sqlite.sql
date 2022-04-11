CREATE TABLE IF NOT EXISTS user (
    username     VARCHAR(255) NOT NULL PRIMARY KEY,
    password         VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS access_token (
    username     VARCHAR(255) NOT NULL,
    access_token         VARCHAR(255) NOT NULL PRIMARY KEY,
    expires_at_epoch_sec INT
);

CREATE TABLE IF NOT EXISTS todo (
    todo_id  VARCHAR(255) NOT NULL PRIMARY KEY,
    username     VARCHAR(255) NOT NULL,
    todo         VARCHAR(255) NOT NULL,
    create_at_epoch_sec INT
);

INSERT INTO user (username, password) VALUES ('init', 'password');
CREATE INDEX todo_idx ON todo(username, create_at_epoch_sec);
