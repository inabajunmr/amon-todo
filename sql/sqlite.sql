CREATE TABLE IF NOT EXISTS user (
    username     VARCHAR(255) NOT NULL PRIMARY KEY,
    password         VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS access_token (
    username     VARCHAR(255) NOT NULL,
    access_token         VARCHAR(255) NOT NULL PRIMARY KEY,
    expires_at_epoch_sec INT
);

INSERT INTO user (username, password) VALUES ('init', 'password');
