# Setting up Docker for the Course

## 1. Verify Docker Installation

```bash
docker --version
```

> [!IMPORTANT]
> If you don't have Docker installed, please follow the instructions in the [Docker Installation Guide](https://docs.docker.com/get-docker/).


## 1. Pull `ubuntu:latest` Docker Image from Docker Hub
An image is a read-only template with instructions for creating a Docker container. It provides a convenient way to package and distribute applications.

The `ubuntu:latest` image is the official Ubuntu image from Docker Hub. We will use this image to create a container for our development environment.

- Via CLI
```bash
docker pull ubuntu:latest
```
**Explanation**:
- `docker pull`: This command is used to pull an image from Docker Hub.
- `ubuntu:latest`: This is the image that we are pulling.

> [!TIP]
> You can use the `docker images` command to list all the images on your system.

- Via Docker Desktop
Search for `ubuntu` in the Docker Desktop App and click on the `Pull` button.

## 2. Create a volume for the container
A volume is a persistent data storage mechanism that allows data to persist even after the container is deleted. You can create, delete, or manage volumes using the Docker API or CLI.

```bash
docker volume create ubuntu-volume
```

**Explanation**:
- `docker volume create`: This command is used to create a volume.
- `ubuntu-volume`: This is the name of the volume.


## 3. Create a container from the `ubuntu:latest` image
A container is a runnable instance of an image. You can create, start, stop, move, or delete a container using the Docker API or CLI.

```bash
docker run -it --name ubuntu-cli -v ubuntu-volume:/data ubuntu:latest
```
**Explanation**:
- `-it`: This flag is used to run the container in interactive mode.
- `--name ubuntu-cli`: This flag is used to name the container.
- `-v ubuntu-volume:/data`: This flag is used to mount the volume `ubuntu-volume` to the `/data` directory in the container.
- `ubuntu:latest`: This is the image from which the container is created.

> [!NOTE]
> You are now inside the container. You can run any command that you would run on an Ubuntu machine. The current path is root (`/`). Try to list the directories using the `ls` command.

> [!TIP]
> You can exit the container by typing `exit` and pressing `Enter`. 

## 4. Update and Clean the Container
To update the container and clean up the unnecessary files, run the following commands:
```bash
apt-get update
apt-get upgrade -y
apt-get clean
```

## 5. To start/stop the container

```bash
docker start ubuntu-cli
docker stop ubuntu-cli
```

> [!TIP]
> You can use the `docker ps` command to list all the running containers.

## 6. To enter the container CLI

```bash
docker exec -it ubuntu-cli bash
```

**Explanation:**
- `docker exec`: This command is used to run a command in a running container.
- `-it`: This flag is used to run the command in interactive mode.
- `ubuntu-cli`: This is the name of the container.
- `bash`: This is the command that we want to run in the container.



## 7. Transfer files between the host and the container
You can use the `docker cp` command.

```bash
docker cp ubuntu-cli:/home/ubuntu/filepath /path/to/destination
```

**Explanation**:
- `docker cp`: This command is used to copy files between the host and the container.
- `ubuntu-cli`: This is the name of the container.
- `/home/ubuntu/filepath`: This is the path of the file in the container.
- `/path/to/destination`: This is the path where you want to copy the file on the host.

> [!TIP]
> You can use the `docker cp` command to copy files from the host to the container or vice versa.

You are all set to use Docker for the course 🎉