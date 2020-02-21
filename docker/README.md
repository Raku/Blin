# Blin Docker image

The `dblin` script wraps the docker commands. It takes the same parameters as
`blin.p6`

```
$ ./dblin SomeModuleHere AnotherModuleHere
$ ./dblin -old=2018.06 --new=2018.09 Foo::Regressed Foo::Regressed::Very Foo::Dependencies::B-on-A
$ ./dblin
```

Depending on the local docker configuration, `sudo` may be needed. In the
container the Blin directory is copies to /mnt where the outside volume is
mounted. `dblin` uses the volume '/var/tmp/Blin-volume'.

Images will be automatically built from the `master` branch with the "latest"
tag. If you want to test changes, use the `rc` branch. Images will be
automatically created with the "rc" tag:

```
rakudo/blin:latest
rakudo/blin:rc
```

Add new binary dependencies to the image by adding them to
[pkg-dependencies](pkg-dependencies).

The `rakudo/blin` image in the [Docker Hub](https://cloud.docker.com) is
automatically built from this repo. Master commits are tagged as "latest",
git tags in the form of `/^v(\d+\.\d+\.\d+)$/` are used as Docker tags with
the `v` prefix excluded, e.g:

```
master: rakudo/blin:latest
tag v1.0.1: rakudo/blin:1.0.1

```
