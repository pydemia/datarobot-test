FROM openjdk:11-jre-slim-buster

# Install Python 3.7 to support standard plugins
RUN set -eux \
        \
        && apt-get update \
        && apt-get install -y --no-install-recommends \
                python3 \
                python3-pip \
                python3-setuptools \
                python3-venv \
                python3-wheel \
                bzip2 \
                file \
                xz-utils \
        \
        && rm -rf /var/lib/apt/lists/* \
        && groupadd -r datarobot && useradd -r -g datarobot datarobot \
        \
        && id datarobot

ENV BOSUN_BASE_LOC="/opt/datarobot/mlops/bosun"
ENV BOSUN_LOG_PROPERTIES=stdout.mlops.log4j2.properties
ENV BOSUN_CONF_LOC="${BOSUN_BASE_LOC}/conf/mlops.bosun.conf.yaml"
ENV START_DELAY=""
ENV MLOPS_API_TOKEN=""
ENV JAVA_OPTIONS=""
ENV TMPDIR=/tmp/bosun

RUN set -xe \
        \
        && mkdir -p "${TMPDIR}" "${BOSUN_BASE_LOC}" \
        && chown -R datarobot:datarobot "${BOSUN_BASE_LOC}" "${TMPDIR}" \
        && usermod -d ${BOSUN_BASE_LOC} datarobot

WORKDIR /tmp/python
COPY lib/requirements_bosun.txt requirements.txt
RUN set -xe \
        \
        && python3 -m pip install --no-cache-dir -U pip \
        && python3 -m pip install --no-cache-dir -r requirements.txt

COPY lib/*.whl ./
RUN python3 -m pip install --no-cache-dir --prefer-binary *.whl \
	&& ln /usr/local/share/mlops/mlops-agent-*.jar ${BOSUN_BASE_LOC}/mlops-agents.jar

COPY --chown=datarobot:datarobot conf ${BOSUN_BASE_LOC}/conf

COPY entrypoint.sh /

USER datarobot
WORKDIR ${BOSUN_BASE_LOC}/run
ENTRYPOINT ["/entrypoint.sh"]

ARG version=none
LABEL com.datarobot.bosun.version=$version
