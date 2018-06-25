require "minitest/autorun"

require "../src/pg_ext"
require "../src/mysql_ext"

require "../src/rome"

unless ENV["DATABASE_URL"]?
  Rome.database_url = "postgres://postgres@/rome_test"
end

Rome.connection do |db|
  db.exec "DROP TABLE IF EXISTS groups;"
  db.exec "DROP TABLE IF EXISTS users;"

  case URI.parse(Rome.database_url).scheme
  when "postgres"
    db.exec <<-SQL
    CREATE TABLE groups (
      id SERIAL NOT NULL PRIMARY KEY,
      name VARCHAR NOT NULL,
      description TEXT
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE users (
      uuid UUID NOT NULL PRIMARY KEY,
      group_id INT NOT NULL,
      name VARCHAR NOT NULL,
      created_at TIMESTAMP NOT NULL,
      updated_at TIMESTAMP NOT NULL
    );
    SQL

  when "mysql"
    db.exec <<-SQL
    CREATE TABLE groups (
      id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(50) NOT NULL,
      description TEXT
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE users (
      uuid CHAR(36) NOT NULL PRIMARY KEY,
      group_id INT NOT NULL,
      name VARCHAR(50) NOT NULL,
      created_at TIMESTAMP NOT NULL,
      updated_at TIMESTAMP NOT NULL
    );
    SQL
  end
end

Minitest.after_run do
  Rome.connection do |db|
    db.exec "DROP TABLE IF EXISTS groups;"
    db.exec "DROP TABLE IF EXISTS users;"
  end
end

class Group < Rome::Model
  columns(
    id:          {type: Int32, primary: true},
    name:        {type: String},
    description: {type: String, nilable: true},
  )
end

class User < Rome::Model
  set_primary_key = :uuid

  columns(
    uuid:       {type: UUID, primary: true},
    group_id:   {type: Int32},
    name:       {type: String},
    created_at: {type: Time, nilable: true},
    updated_at: {type: Time, nilable: true},
  )
end
