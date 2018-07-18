require "minitest/autorun"

require "../src/pg_ext"
require "../src/mysql_ext"

require "../src/rome"

unless ENV["DATABASE_URL"]?
  Rome.database_url = "postgres://postgres@/rome_test"
end

Minitest.after_run do
  Rome.connection do |db|
    db.exec "DROP TABLE IF EXISTS groups;"
    db.exec "DROP TABLE IF EXISTS users;"
  end
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

class Group < Rome::Model
  columns(
    id:          {type: Int32, primary_key: true},
    name:        {type: String},
    description: {type: String, null: true},
  )
end

class User < Rome::Model
  columns(
    uuid:       {type: UUID, primary_key: true},
    group_id:   {type: Int32},
    name:       {type: String},
    created_at: {type: Time, null: true},
    updated_at: {type: Time, null: true},
  )
end

1.upto(2) do |group_id|
  group = Group.create(name: "Group ##{group_id}")

  1.upto(2) do |index|
    User.create(uuid: UUID.random, group_id: group.id, name: "User ##{group_id}-#{index}")
  end
end
