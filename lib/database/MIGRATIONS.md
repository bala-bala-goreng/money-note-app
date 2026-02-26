# Database Migrations

When you change the schema (add columns, new tables), follow these steps so **existing users keep their data** when they update the app.

## Adding a new column

1. **Bump `dbVersion`** in `database_helper.dart` (e.g. 6 → 7).

2. **Add a migration** in `_runMigration`:

```dart
// v6 -> v7: new_column on some_table
if (from < 7) {
  await DatabaseHelper.addColumnIfMissing(
    db, 'some_table', 'new_column', 'TEXT',
    // For NOT NULL, always add defaultValue so existing rows get a value:
    // defaultValue: '0',  or  defaultValue: "''",  or  defaultValue: 'NULL'
  );
}
```

3. **Update `_onCreate`** – add the column to the CREATE TABLE for fresh installs.

## Adding a new table

1. Bump `dbVersion`.
2. In `_runMigration`:

```dart
if (from < 7) {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS new_table (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ...
    )
  ''');
}
```

3. Add the same CREATE TABLE in `_onCreate`.

## Rules

- **Never** DROP tables that have user data.
- **Always** use `addColumnIfMissing` for new columns – it checks if the column exists first.
- For NOT NULL columns, **always** provide `defaultValue` so existing rows get a value.
- Migrations run in order. Old users upgrade step-by-step; new users get the full schema from `_onCreate`.
