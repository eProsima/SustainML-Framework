FROM  ubuntu:22.04
LABEL author=raul@eprosima.com

# Avoid interactuation with installation of some package that needs the locale.
ENV TZ=Europe/Madrid
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Avoids using interactions during building
ENV DEBIAN_FRONTEND=noninteractive

# Use a bash shell so it is possible to run things like `source` (required for colcon builds)
SHELL ["/bin/bash", "-c"]

# Install dependencies
RUN apt update && apt install --yes --no-install-recommends \
        wget git cmake g++ build-essential python3 python3.10-venv python3-pip libpython3-dev swig \
        libssl-dev libasio-dev libtinyxml2-dev libp11-dev libengine-pkcs11-openssl softhsm2 \
        qtdeclarative5-dev libqt5charts5-dev qml-module-qtcharts \
        qtquickcontrols2-5-dev libqt5svg5 qml-module-qtquick-controls \
        qml-module-qtquick-controls2 qml-module-qt-labs-qmlmodels && \
    pip3 install -U \
        colcon-common-extensions vcstool

# Set the SustainML working directory
WORKDIR /sustainml

# default run node is the orchestrator
ENV node=back-end

# Copy the bash script entrypoint file
COPY run.bash /run.bash

# Provide permissions to the run.bash file
RUN chmod +x /run.bash

# Define arguments for setting the branches of each repository
ARG fastcdr_branch
ARG fastdds_branch
ARG devutils_branch
ARG sustainml_lib_branch
ARG sustainml_framework_branch

# Clone the repositories and checkout the branches if set
RUN wget https://raw.githubusercontent.com/eProsima/SustainML-Framework/main/sustainml.repos && \
    mkdir src && vcs import src < sustainml.repos && \
    if [ -n "${fastcdr_branch}" ]; then \
        cd src/fastcdr && git checkout ${fastcdr_branch} && cd ../.. ; \
    fi && \
    if [ -n "${fastdds_branch}" ]; then \
        cd src/fastdds && git checkout ${fastdds_branch} && cd ../.. ; \
    fi && \
    if [ -n "${devutils_branch}" ]; then \
        cd src/dev-utils && git checkout ${devutils_branch} && cd ../.. ; \
    fi && \
    if [ -n "${sustainml_lib_branch}" ]; then \
        cd src/sustainml_lib && git checkout ${sustainml_lib_branch} && cd ../.. ; \
    fi && \
    if [ -n "${sustainml_framework_branch}" ]; then \
        cd src/sustainml_framework && git checkout ${sustainml_framework_branch} && cd ../.. ; \
    fi

# Initialize the sustainml library submodules
RUN cd /sustainml/src/sustainml_lib && git submodule update --init --recursive && cd /sustainml
# Install the submodules dependencies
RUN pip3 install -r /sustainml/src/sustainml_lib/sustainml_modules/requirements.txt
RUN pip install hf_xet
# Build the projects
RUN colcon build --event-handlers console_direct+

# Load Neo4j backups and adjust permissions
RUN sudo neo4j-admin database load system \
      --from-path=/home/eprosima/SustainML/SustainML_ws/src/sustainml_lib/sustainml_modules/sustainml_modules/sustainml-wp1/rag/neo4j_backup \
      --overwrite-destination=true && \
    sudo neo4j-admin database load neo4j \
      --from-path=/home/eprosima/SustainML/SustainML_ws/src/sustainml_lib/sustainml_modules/sustainml_modules/sustainml-wp1/rag/neo4j_backup \
      --overwrite-destination=true && \
    sudo chown -R neo4j:neo4j /var/lib/neo4j/data

ENTRYPOINT ["/run.bash" ]
