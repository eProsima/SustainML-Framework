# SustainML Framework deployment with Docker

This section describes the tools to deploy the SustainML Framework using Docker containers on an Ubuntu host.

In this folder, there are three different files:

1. ``Dockerfile``: builds an Ubuntu 24.04 image with all the dependencies, the SustainML workspace built with colcon, the ANN index of the models knowledge base and the Neo4j database already loaded.
    It clones the repositories listed in the ``sustainml.repos`` file of the ``main`` branch of this repository.
1. ``run.bash``: entrypoint script used inside the SustainML Docker container to start the node selected by the ``SUSTAINML_NODE`` environment variable.
1. ``docker-compose.yaml``: compose file that uses both Docker image and entrypoint to deploy one container per SustainML node, plus the GUI.

The ``docker-compose.yaml`` file deploys the following containers, all of them on the host network:

* ``desktop``: the SustainML Framework GUI, shown on the X server of the host.
* ``back_end``: the backend node, which hosts the orchestrator and the REST API used by the GUI (``http://127.0.0.1:5001``).
* ``app_requirements``, ``ml_model_metadata``, ``ml_model``, ``hw_constraints``, ``hw_resources`` and ``carbon_tracker``: the module nodes.
    The ``ml_model_metadata`` container also starts the Neo4j database used by the ML Model Metadata and ML Model Provider nodes.
    The ``carbon_tracker`` container mounts ``/sys`` read-only to measure the energy consumption.
* ``front_end``: the web front end of work package 4, which the GUI does not use.

To run the SustainML Framework using Docker, please follow these steps:

1. Install Docker Engine and its Compose plugin (the ``docker compose`` command), following the [Docker documentation](https://docs.docker.com/engine/install/ubuntu/).
1. Install [Ollama](https://ollama.com/) on the host and pull the ``llama3`` model.
    The containers do not include Ollama: the nodes reach the Ollama server of the host at ``http://localhost:11434``.

    ```bash
    curl -fsSL https://ollama.com/install.sh | sh && \
    ollama pull llama3
    ```

1. Navigate to this folder.
1. Build the Docker image by running the following command.
    The ``sustainml:v0.2.0`` name and tag are the ones that ``docker-compose.yaml`` uses.

    ```bash
    docker build -f Dockerfile -t sustainml:v0.2.0 .
    ```

    The branch of each repository can be changed with the build arguments ``fastcdr_branch``, ``fastdds_branch``, ``devutils_branch``, ``sustainml_lib_branch`` and ``sustainml_framework_branch`` (for example, ``--build-arg sustainml_lib_branch=<branch>``).

1. Set the ``HF_TOKEN`` environment variable on your host to your personal Hugging Face access token.
    ``docker-compose.yaml`` passes it to the backend container, which forwards it to the nodes that download models from the Hugging Face Hub, so that gated models can be loaded.

    ```bash
    export HF_TOKEN=<your_huggingface_token>
    ```

1. Optionally, set the environment variable ``SUSTAINML_DOMAIN_ID`` to change the DDS domain (``0`` by default) used for the communication between the nodes.
    ``docker-compose.yaml`` passes it to the backend and module node containers.

    ```bash
    export SUSTAINML_DOMAIN_ID=<domain_id>
    ```

1. If you want to run your own SustainML node independently, comment the corresponding container entry in the ``docker-compose.yaml`` file.
1. Provide privileges to the X localhost server and deploy the Docker containers using Docker compose:

    ```bash
    xhost local:root && \
    docker compose up
    ```
