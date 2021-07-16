FROM openjdk:11-jre-slim-buster

ENV AGENT_BASE_LOC="/opt/datarobot/mlops/agent"
ENV AGENT_LOG_PROPERTIES=stdout.mlops.log4j2.properties
ENV AGENT_CONF_LOC="${AGENT_BASE_LOC}/conf/mlops.agent.conf.yaml"
ENV START_DELAY=""
ENV MLOPS_SERVICE_URL=""
ENV MLOPS_API_TOKEN=""
ENV JAVA_OPTIONS=""
ENV TMPDIR=/tmp/ta

RUN set -xe \
        \
	&& mkdir -p "${TMPDIR}" "${AGENT_BASE_LOC}" \
	&& groupadd -r datarobot && useradd -r -g datarobot datarobot \
	&& chown -R datarobot "${AGENT_BASE_LOC}" "${TMPDIR}" \
	&& chgrp -R datarobot "${AGENT_BASE_LOC}" "${TMPDIR}"

COPY --chown=datarobot:datarobot lib/mlops-agent-*.jar ${AGENT_BASE_LOC}/mlops-agents.jar
COPY --chown=datarobot:datarobot conf ${AGENT_BASE_LOC}/conf

COPY entrypoint.sh /

USER datarobot
WORKDIR ${AGENT_BASE_LOC}/run
ENTRYPOINT ["/entrypoint.sh"]

ARG version=none
LABEL com.datarobot.agent.version=$version
