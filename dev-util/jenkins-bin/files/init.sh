#!/sbin/runscript

depend() {
    need net
    use dns logger mysql postgresql
}

JENKINS_PIDFILE=/var/run/jenkins/jenkins.pid
JENKINS_WAR=/usr/lib/jenkins/jenkins.war

RUN_AS=jenkins

checkconfig() {
    if [ ! -n "$JENKINS_HOME" ] ; then
        eerror "JENKINS_HOME not configured"
        return 1
    fi
    if [ ! -d "$JENKINS_HOME" ] ; then
        eerror "JENKINS_HOME directory does not exist: $JENKINS_HOME"
        return 1
    fi
    return 0
}

start() {
    checkconfig || return 1

    JAVA_HOME=`java-config --jre-home`
    COMMAND=$JAVA_HOME/bin/java

    JAVA_PARAMS="$JENKINS_JAVA_OPTIONS -DJENKINS_HOME=$JENKINS_HOME -jar $JENKINS_WAR"

    # Don't use --daemon here, because in this case stop will not work
    PARAMS="--logfile=/var/log/jenkins/jenkins.log"
    [ -n "$JENKINS_PORT" ] && PARAMS="$PARAMS --httpPort=$JENKINS_PORT"
    [ -n "$JENKINS_DEBUG_LEVEL" ] && PARAMS="$PARAMS --debug=$JENKINS_DEBUG_LEVEL"
    [ -n "$JENKINS_HANDLER_STARTUP" ] && PARAMS="$PARAMS --handlerCountStartup=$JENKINS_HANDLER_STARTUP"
    [ -n "$JENKINS_HANDLER_MAX" ] && PARAMS="$PARAMS --handlerCountMax=$JENKINS_HANDLER_MAX"
    [ -n "$JENKINS_HANDLER_IDLE" ] && PARAMS="$PARAMS --handlerCountMaxIdle=$JENKINS_HANDLER_IDLE"
    [ -n "$JENKINS_ARGS" ] && PARAMS="$PARAMS $JENKINS_ARGS"

    if [ "$JENKINS_ENABLE_ACCESS_LOG" = "yes" ]; then
        PARAMS="$PARAMS --accessLoggerClassName=winstone.accesslog.SimpleAccessLogger --simpleAccessLogger.format=combined --simpleAccessLogger.file=/var/log/jenkins/access_log"
    fi

    local piddir="${JENKINS_PIDFILE%/*}"
    if [ ! -d "$piddir" ] ; then
        mkdir "$piddir" && \
        chown $RUN_AS "$piddir"
        rc=$?
        if [ $rc -ne 0 ]; then
            eerror "Directory $piddir for pidfile does not exist and cannot be created"
            return 1
            fi
    fi

    ebegin "Starting ${SVCNAME}"
    start-stop-daemon --start --quiet --background \
        --make-pidfile --pidfile $JENKINS_PIDFILE \
        --user $RUN_AS \
        --exec "${COMMAND}" -- $JAVA_PARAMS $PARAMS
    eend $?
}

stop() {
    ebegin "Stopping ${SVCNAME}"
    start-stop-daemon --stop --quiet --pidfile $JENKINS_PIDFILE
    eend $?
}
