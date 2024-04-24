# Use the vulcanexus image to avoid the need to install dependencies
FROM  ubuntu:22.04
LABEL author=raul@eprosima.com

# Avoid interactuation with installation of some package that needs the locale.
ENV TZ=Europe/Madrid
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Avoids using interactions during building
ENV DEBIAN_FRONTEND=noninteractive

# Use a bash shell so it is possigle to run things like `source` (required for colcon builds)
SHELL ["/bin/bash", "-c"]

# Install dependencies
RUN apt-get update && apt-get install --yes --no-install-recommends \
        git \
        wget \
        build-essential \
        software-properties-common \
        cmake \
        python3 \
        python3-pip \
        libpython3-dev \
        swig \
        libssl-dev \
        libasio-dev \
        libtinyxml2-dev \
        libp11-dev \
        libengine-pkcs11-openssl \
        softhsm2 \
        gnutls-bin \
        libacl1-dev \
        qtdeclarative5-dev \
        libqt5charts5-dev \
        qtquickcontrols2-5-dev \
        libfuse-dev \
        libgl-dev \
        libharfbuzz0b \
        libgl1-mesa-glx \
        mesa-utils \
        libqt53dcore5 \
        libqt5charts5 \
        libqt5widgets5 \
        libqt5quickcontrols2-5 \
        libqt5scripttools5 \
        libqt5qml5 \
        libqt5qmlmodels5 \
        libqt5qmlworkerscript5 \
        libqt5quick5 \
        libqt5quickshapes5 \
        libqt5quickwidgets5 \
        libqt5svg5 \
        qt5-qmltooling-plugins \
        qml-module-qt-labs-calendar \
        qml-module-qt-labs-folderlistmodel \
        qml-module-qt-labs-settings \
        qml-module-qtcharts \
        qml-module-qtgraphicaleffects \
        qml-module-qtqml \
        qml-module-qtquick-controls2 \
        qml-module-qtquick-controls \
        qml-module-qtquick-dialogs \
        qml-module-qtquick-layouts \
        qml-module-qtquick-privatewidgets \
        qml-module-qtquick-templates2 \
        qml-module-qtquick-window2 \
        qml-module-qtquick2 && \
    pip3 install -U \
        colcon-common-extensions \
        vcstool

# Set the SustainML working directory
WORKDIR /sustainml

# Set the branch per each repository
ARG fastcdr_branch=v2.2.0
ARG fastdds_branch=v2.14.0
ARG devutils_branch=main
ARG sustainml_branch=feature/architecture_update
ARG sustainml_lib_branch=feature/baseline_topics

# default run node is the orchestrator
ENV node orchestrator

# Copy the bash script entrypoint file
COPY run.bash /run.bash

# Provide permissions to the run.bash file
RUN chmod +x /run.bash

# Print the branches that are going to be used
RUN echo "fastcdr branch: <${fastcdr_branch}>" && \
    echo "fastdds branch: <${fastdds_branch}>" && \
    echo "devutils branch: <${devutils_branch}>" && \
    echo "sustainml branch: <${sustainml_branch}>" && \
    echo "sustainml_lib branch: <${sustainml_lib_branch}>"

# Clone the repositories and checkout the branches
RUN wget https://raw.githubusercontent.com/eProsima/SustainML-Frontend/main/sustainml.repos && \
    mkdir src && vcs import src < sustainml.repos && \
    cd src/fastcdr && git checkout ${fastcdr_branch} && cd ../.. && \
    cd src/fastdds && git checkout ${fastdds_branch} && cd ../.. && \
    cd src/dev-utils && git checkout ${devutils_branch} && cd ../.. && \
    cd src/sustainml && git checkout ${sustainml_branch} && cd ../.. && \
    cd src/sustainml_lib && git checkout ${sustainml_lib_branch} && cd ../..

# Build the projects
RUN colcon build --event-handlers console_direct+

ENTRYPOINT ["/run.bash" ]
