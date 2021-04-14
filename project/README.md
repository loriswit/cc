# Cloud Computing Project

By [Boris Mottet](https://gitlab.com/Risbobo) and [Loris Witschard](https://gitlab.com/loriswit)

## Usage

Start all services by running:
```sh
docker-compose up
```

**Note**: watches will be imported into the database (from *watches.sql*) only once.
If the volume (*watch-volume*) already exists, they won't be imported again.
