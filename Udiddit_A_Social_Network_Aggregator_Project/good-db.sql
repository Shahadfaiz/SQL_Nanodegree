-- create users table
CREATE TABLE users(
    id SERIAL PRIMARY KEY,
    username VARCHAR(25) NOT NULL UNIQUE,
    last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT user_name_not_empty CHECK (LENGTH(TRIM(username)) > 0)
);

--create topics table
CREATE TABLE topics(
    id SERIAL PRIMARY KEY,
    topic_name VARCHAR(30) NOT NULL UNIQUE,
    topic_description VARCHAR(500),

    CONSTRAINT topic_name_not_empty CHECK (LENGTH(TRIM(topic_name)) > 0)
);

-- create posts table
CREATE TABLE posts(
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    topic_id INTEGER NOT NULL ,
    user_id INTEGER ,
    url VARCHAR(2000),
    text_content  TEXT, 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT post_title_not_empty CHECK (LENGTH(TRIM(title)) > 0),
    CONSTRAINT either_ur_or_text_content CHECK ( (url IS NOT NULL AND text_content IS NULL) OR (url IS NULL AND text_content IS NOT NULL) ),
    CONSTRAINT fk_topic FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE, -- topic_deleted_post_deleted
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL -- user_deleted_post_remain
);

-- create comments table
CREATE TABLE comments(
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    user_id INTEGER ,
    parent_comment_id INTEGER ,
    text_content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT comment_not_empty CHECK (LENGTH(TRIM(text_content)) > 0),
    CONSTRAINT fk_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE, -- post_deleted_comments_deleted
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL, -- user_deleted_comment_remain
    CONSTRAINT fk_parent_comment FOREIGN KEY (parent_comment_id) REFERENCES comments(id) ON DELETE CASCADE -- comment_deleted_decendants_deleted
);

--create votes table
CREATE TABLE votes(
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    user_id INTEGER ,
    vote_value INTEGER NOT NULL,

    CONSTRAINT vote_value_check CHECK (vote_value IN (-1,1)), -- 1 upvote, -1 downvote
    CONSTRAINT fk_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE, -- post_deleted_votes_deleted
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL, -- user_deleted_votes_remain
    CONSTRAINT one_vote_per_user_per_post UNIQUE (post_id, user_id)
);

-- create indexes
CREATE INDEX idx_users_last_login ON users(last_login);

CREATE INDEX idx_votes_posts ON votes(post_id);
CREATE INDEX idx_votes_users ON votes(user_id);

CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_users_id ON comments(user_id);
CREATE INDEX idx_comments_parent_id ON comments (parent_comment_id);
CREATE INDEX idx_comments_created_at ON comments(created_at);

CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_topic_id ON posts(topic_id);
CREATE INDEX idx_posts_url ON posts(url);
CREATE INDEX idx_posts_created_at ON posts(created_at);

-- migrate unique users from all sources
INSERT INTO users(username) (
    SELECT DISTINCT username 
    FROM (
        SELECT username FROM bad_posts
        UNION 
        SELECT username FROM bad_comments
        UNION 
        SELECT DISTINCT regexp_split_to_table(upvotes,',') AS username FROM bad_posts
        UNION
        SELECT DISTINCT regexp_split_to_table(downvotes,',') AS username FROM bad_posts
        
    ) all_usernames
    WHERE username IS NOT NULL
);

-- migrate unique topics from bad_posts
INSERT INTO topics(topic_name) (
    SELECT DISTINCT topic
    FROM bad_posts
    WHERE topic IS NOT NULL
);

INSERT INTO posts(title, topic_id, user_id, url, text_content) (
    SELECT 
        SUBSTRING(bp.title, 1, 100) as title,
        t.id AS topic_id, 
        u.id AS user_id, 
        bp.url,
        bp.text_content
    FROM bad_posts bp
    JOIN topics t ON t.topic_name = bp.topic
    LEFT JOIN users u ON u.username = bp.username
);

-- migrate comments
INSERT INTO comments(post_id, user_id, text_content) (
    SELECT 
        bc.post_id, 
        u.id AS user_id, 
        bc.text_content
    FROM bad_comments bc
    LEFT JOIN users u ON u.username = bc.username
);

-- migrate upvotes
INSERT INTO votes(post_id, user_id, vote_value) (
    SELECT 
        bp.id AS post_id, 
        u.id AS user_id, 
        1 AS vote_value
    FROM bad_posts bp
    CROSS JOIN regexp_split_to_table(bp.upvotes, ',') AS upvoter(username)
    JOIN users u ON u.username = upvoter.username
);
-- migrate downvotes
INSERT INTO votes(post_id, user_id, vote_value) (
    SELECT 
        bp.id AS post_id, 
        u.id AS user_id, 
        -1 AS vote_value
    FROM bad_posts bp
    CROSS JOIN regexp_split_to_table(bp.downvotes, ',') AS downvoter(username)
    JOIN users u ON u.username = downvoter.username
);

DROP TABLE bad_comments; 
DROP TABLE bad_posts;