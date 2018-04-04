CREATE TABLE domains (
    id SERIAL PRIMARY KEY,
    domain character varying(255) NOT NULL,
    UNIQUE (domain)
);

CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    username character varying(255) NOT NULL,
    domain character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    quota int DEFAULT 0 NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    sendonly boolean DEFAULT false NOT NULL,
    UNIQUE (username, domain),
    FOREIGN KEY (domain) REFERENCES domains (domain)
);

CREATE TABLE aliases (
    id SERIAL PRIMARY KEY,
    source_username character varying(255) NOT NULL,
    source_domain character varying(255) NOT NULL,
    destination_username character varying(255) NOT NULL,
    destination_domain character varying(255) NOT NULL,
    is_regex boolean DEFAULT false NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    UNIQUE (source_username, source_domain, destination_username, destination_domain),
    FOREIGN KEY (source_domain) REFERENCES domains (domain)
);

CREATE TYPE policy_t AS ENUM ('none', 'may', 'encrypt', 'dane', 'dane-only', 'fingerprint', 'verify', 'secure');

CREATE TABLE tlspolicies (
    id SERIAL PRIMARY KEY,
    domain character varying(255) NOT NULL,
    policy policy_t NOT NULL,
    params character varying(255),
    UNIQUE (domain)
);
