# CONTRIBUTE

1. Install the required shards:
```console
$ shards install
```

2. Run tests against PostgreSQL:
```console
$ sudo -u postgres createdb rome_test
$ export DATABASE_URL=postgres://postgres@/rome_test
$ crystal run test/*_test.cr
```

3. Run tests against MySQL:
```console
$ mysqladmin create rome_test -u root --default-character-set=utf8mb4
$ export DATABASE_URL=mysql://root@/rome_test
$ crystal run test/*_test.cr
```
