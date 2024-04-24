# SustainML Framework deployment with Docker

This section describes the tools to deploy the SustainML Framework using Docker containers.

In this folder, there are three different files:

1. ``Dockerfile``: Dockerfile for download, build  and install the SustainML framework.
1. ``run.bash``: script used as an entrypoint in the SustainML Docker container to run the selected node based on an input argument.
1. ``docker-compos.yaml``: compose file that uses both Docker image and entrypoint to deploy all the SustainML Framework nodes.

To run the SustainML Framework using Docker, please follow these steps:

1. Navigate to this folder.
1. Build the Docker image by running the following command:

   ```bash
   docker build -f Dockerfile -t sustainml:v0.1.0 .
   ```

1. If you want to run your own SustainML node apart, comment the corresponding container entry in the ``docker-compose.yaml`` file.
1. Deploy the Docker containers using Docker compose:

    ```bash
    docker compose up
    ```
