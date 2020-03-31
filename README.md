# Re2o Docker for devs

This is simply a docker environment to dev re2o locally.

To use it :

* clone Re2o;
* copy `Dockerfile` and `docker-compose.yml` into the cloned directory;
* copy `settings_local.py` into the `re2o` folder in the cloned directory;
* run `docker-compose up`

The apache server and migrations are updated every time you relauch the `docker-compose` command. To enter a shell in the execution environment, you can use

```
docker ps
```

to find the id of the re2o environment, then

```
docker exec -it <ID> bash
```

KEEP IN MIND THAT THIS IS A DEV ENVIRONMENT NOT MEANT FOR PRODUCTION USE.
