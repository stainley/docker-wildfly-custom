# Use latest jboss/base-jdk:11 image as the base
FROM jboss/base-jdk:11
LABEL maintener="Stainley Lebron <stainley.lebron@gmail.com>"

# Set the WILDFLY_VERSION env variable
ENV JBOSS_HOME /opt/jboss/wildfly
ENV WILDFLY_VERSION 18.0.0.Beta1
ENV WILDFLY_SHA1 eaef7a87062837c215e54511c4ada8951f0bd8d5
ENV DEPLOYMENTS /standalone/deployments/

ENV MYSQL_HOST 127.0.0.1:3306
ENV MYSQL_USER admin
ENV MYSQL_PASSWORD Admin#1234
ENV MYSQL_DATABASE rental_car

USER root

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd $HOME \
    && curl -O https://download.jboss.org/wildfly/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.tar.gz \
    #&& sha1sum wildfly-${WILDFLY_VERSION}.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-${WILDFLY_VERSION}.tar.gz \
    && mv $HOME/wildfly-${WILDFLY_VERSION} $JBOSS_HOME \
    && rm wildfly-${WILDFLY_VERSION}.tar.gz \
    && chown -R jboss:0 ${JBOSS_HOME} \
    && chmod -R g+rw ${JBOSS_HOME}

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

USER jboss

# Copy custom configuration file with Datasources and Drivers
COPY /wildfly-conf/standalone-custom-ds.xml ${JBOSS_HOME}/standalone/configuration/standalone-custom-ds.xml

# Get MySQL Driver
ADD https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.17/mysql-connector-java-8.0.17.jar ${JBOSS_HOME}/modules/system/layers/base/com/mysql/jdbc/main/mysql-connector-java-8.0.17-bin.jar

# MYSQL JDBC Module
COPY /wildfly-conf/module-mysql.xml ${JBOSS_HOME}/modules/system/layers/base/com/mysql/jdbc/main/module.xml


# Create admin and password
RUN /opt/jboss/wildfly/bin/add-user.sh admin Admin#1234 --silent

VOLUME ${JBOSS_HOME}/standalone/deployments/

RUN mkdir -p ${JBOSS_HOME}/standalone/log/
VOLUME ${JBOSS_HOME}/standalone/log/
CMD true

# Expose the ports we're interested in
#EXPOSE 8080 9990


# Set the default command to run on boot
# This will boot WildFly in the custom mode and bind to all interface
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0", "-c", "standalone-custom-ds.xml", "-Dmysql.host=${MYSQL_HOST}", "-Dmysql.username=${MYSQL_USER}", "-Dmysql.password=${MYSQL_PASSWORD}", "-Dmysql.database=${MYSQL_DATABASE}"]

#ADD your-awesome-app.war /opt/jboss/wildfly/${DEPLOYMENTS}/