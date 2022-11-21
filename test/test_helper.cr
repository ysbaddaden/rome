require "minitest/autorun"

require "../src/pg_ext"
require "../src/mysql_ext"
require "../src/sqlite3_ext"
require "../src/rome"

unless ENV["DATABASE_URL"]?
  Rome.database_url = "postgres://postgres@/rome_test"
end

module TransactionalTests
  def before_setup
    @transaction = Rome.begin_transaction
    super
  end

  def after_teardown
    super
  ensure
    if tx = @transaction
      tx.rollback unless tx.closed?
    end
    Rome.release
  end
end

Minitest.after_run do
  Rome.connection do |db|
    db.exec "DROP TABLE IF EXISTS groups;"
    db.exec "DROP TABLE IF EXISTS users;"
    db.exec "DROP TABLE IF EXISTS authors;"
    db.exec "DROP TABLE IF EXISTS books;"
    db.exec "DROP TABLE IF EXISTS suppliers;"
    db.exec "DROP TABLE IF EXISTS accounts;"
  end
end

Rome.connection do |db|
  db.exec "DROP TABLE IF EXISTS groups;"
  db.exec "DROP TABLE IF EXISTS users;"
  db.exec "DROP TABLE IF EXISTS authors;"
  db.exec "DROP TABLE IF EXISTS books;"
  db.exec "DROP TABLE IF EXISTS suppliers;"
  db.exec "DROP TABLE IF EXISTS accounts;"

  uri = URI.parse(Rome.database_url)

  case uri.scheme
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

    db.exec <<-SQL
    CREATE TABLE authors (
      id SERIAL NOT NULL PRIMARY KEY,
      name VARCHAR NOT NULL
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE books (
      id SERIAL NOT NULL PRIMARY KEY,
      author_id INT,
      name VARCHAR NOT NULL
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE suppliers (
      id SERIAL NOT NULL PRIMARY KEY
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE accounts (
      id SERIAL NOT NULL PRIMARY KEY,
      supplier_id INT
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
      uuid BINARY(16) NOT NULL PRIMARY KEY,
      group_id INT NOT NULL,
      name VARCHAR(50) NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE authors (
      id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(50) NOT NULL
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE books (
      id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
      author_id INT,
      name VARCHAR(50) NOT NULL
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE suppliers (
      id INT NOT NULL AUTO_INCREMENT PRIMARY KEY
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE accounts (
      id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
      supplier_id INT
    );
    SQL

  when "sqlite3"
    db.exec <<-SQL
    CREATE TABLE groups (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name VARCHAR(50) NOT NULL,
      description TEXT
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE users (
      uuid BLOB NOT NULL PRIMARY KEY,
      group_id INT NOT NULL,
      name VARCHAR(50) NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE authors (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name VARCHAR(50) NOT NULL
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE books (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      author_id INT,
      name VARCHAR(50) NOT NULL
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE suppliers (
      id INTEGER PRIMARY KEY AUTOINCREMENT
    );
    SQL

    db.exec <<-SQL
    CREATE TABLE accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      supplier_id INT
    );
    SQL

  else
    puts "Unknown database scheme: #{uri.scheme}"
    exit 1
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

class Author < Rome::Model
  columns(
    id:   {type: Int32, primary_key: true},
    name: {type: String},
  )
  has_many :books
end

class Book < Rome::Model
  columns(
    id:        {type: Int32, primary_key: true},
    author_id: {type: Int32},
    name:      {type: String},
  )
  belongs_to :author
end

class BookNilAuthor < Rome::Model
  self.table_name = "books"
  columns(
    id:        {type: Int32, primary_key: true},
    author_id: {type: Int32, null: true},
    name:      {type: String},
  )
  belongs_to :author
end

class Supplier < Rome::Model
  columns(id: {type: Int32, primary_key: true})
  has_one :account
end

class Account < Rome::Model
  columns(
    id: {type: Int32, primary_key: true},
    supplier_id: {type: Int32?},
  )
  belongs_to :supplier
end

1.upto(2) do |group_id|
  group = Group.create(name: "Group ##{group_id}")

  1.upto(2) do |index|
    User.create(uuid: UUID.random, group_id: group.id, name: "User ##{group_id}-#{index}")
  end
end

class AuthorAutosave < Rome::Model
  self.table_name = "authors"
  columns(
    id:   {type: Int32, primary_key: true},
    name: {type: String},
  )
  has_many :books, autosave: true, foreign_key: "author_id"
end

class AuthorNoAutosave < Rome::Model
  self.table_name = "authors"
  columns(
    id:   {type: Int32, primary_key: true},
    name: {type: String},
  )
  has_many :books, autosave: false, foreign_key: "author_id"
end

class BookAutosave < Rome::Model
  self.table_name = "books"
  columns(
    id:        {type: Int32, primary_key: true},
    author_id: {type: Int32},
    name:      {type: String},
  )
  belongs_to :author, autosave: true
end

class BookNoAutosave < Rome::Model
  self.table_name = "books"
  columns(
    id:        {type: Int32, primary_key: true},
    author_id: {type: Int32},
    name:      {type: String},
  )
  belongs_to :author, autosave: false
end

class SupplierAutosave < Rome::Model
  self.table_name = "suppliers"
  columns(id: {type: Int32, primary_key: true})
  has_one :account, autosave: true, foreign_key: "supplier_id"
end

class SupplierNoAutosave < Rome::Model
  self.table_name = "suppliers"
  columns(id: {type: Int32, primary_key: true})
  has_one :account, autosave: false, foreign_key: "supplier_id"
end

class SupplierDependentNullify < Rome::Model
  self.table_name = "suppliers"
  columns(id: {type: Int32, primary_key: true})
  has_one :account, dependent: :nullify, foreign_key: "supplier_id"
end

class SupplierDependentDelete < Rome::Model
  self.table_name = "suppliers"
  columns(id: {type: Int32, primary_key: true})
  has_one :account, dependent: :delete, foreign_key: "supplier_id"
end

class SupplierDependentDestroy < Rome::Model
  self.table_name = "suppliers"
  columns(id: {type: Int32, primary_key: true})
  has_one :account, dependent: :destroy, foreign_key: "supplier_id"
end

class AccountDependentDelete < Rome::Model
  self.table_name = "accounts"
  columns(
    id: {type: Int32, primary_key: true},
    supplier_id: {type: Int32?},
  )
  belongs_to :supplier, dependent: :delete
end

class AccountDependentDestroy < Rome::Model
  self.table_name = "accounts"
  columns(
    id: {type: Int32, primary_key: true},
    supplier_id: {type: Int32?},
  )
  belongs_to :supplier, dependent: :destroy
end

class AuthorDependentDestroy < Rome::Model
  self.table_name = "authors"
  columns(
    id:   {type: Int32, primary_key: true},
    name: {type: String},
  )
  has_many :books, foreign_key: "author_id", dependent: :destroy
end

class AuthorDependentDeleteAll < Rome::Model
  self.table_name = "authors"
  columns(
    id:   {type: Int32, primary_key: true},
    name: {type: String},
  )
  has_many :books, foreign_key: "author_id", dependent: :delete_all
end

class AuthorDependentNullify < Rome::Model
  self.table_name = "authors"
  columns(
    id:   {type: Int32, primary_key: true},
    name: {type: String},
  )
  has_many :books, class_name: BookNilAuthor, foreign_key: "author_id", dependent: :nullify
end
