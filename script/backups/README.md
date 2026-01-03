# Backups

## Nightly database dump
```bash
export DATABASE_URL="postgres://user:password@localhost:5432/waystation_development"
./script/backups/backup_db.sh
```

## Weekly file archive
```bash
./script/backups/backup_files.sh
```

## Example cron entries
```
0 2 * * * /Users/jon/Documents/Projects/Waystation/script/backups/backup_db.sh
0 3 * * 0 /Users/jon/Documents/Projects/Waystation/script/backups/backup_files.sh
```
