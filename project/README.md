# Cloud Computing Project

By [Boris Mottet](https://gitlab.com/Risbobo) and [Loris Witschard](https://gitlab.com/loriswit)

## Usage

Start by building the images:
```sh
./build.sh
```

Then, connect `kubectl` to any cluster and deploy the services:
```shell
./deploy.sh
```

**Note**: this requires authorisation to push to the appropriate DockerHub repositories.

### Database access

Right now, the database address and credentials are hard-coded in `all.yml`. The default values refer to a Cloud SQL database that is available from everywhere. To connect to a different database, you have to manually edit lines 38-51.

This will be improved in a further version to allow easier (and more secure) configuration with environment variables.
