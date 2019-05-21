FROM openjdk:12-jdk-alpine as build
ENV APP_HOME=/usr/app
WORKDIR $APP_HOME
COPY build.gradle settings.gradle gradlew $APP_HOME/
COPY gradle/ $APP_HOME/gradle/
RUN ./gradlew build || return 0
COPY . $APP_HOME
RUN ./gradlew bootJar

FROM openjdk:12-alpine
RUN apk add bash
ENV APP_HOME=/usr/app
WORKDIR $APP_HOME
ENV ARTIFACT_NAME=aaddemo-0.0.1-SNAPSHOT.jar
COPY --from=build $APP_HOME/build/libs/$ARTIFACT_NAME $APP_HOME/
COPY prepare.sh $APP_HOME/prepare.sh
ENV PROFILE docker
EXPOSE 8080
ENTRYPOINT ["$APP_HOME/prepare.sh"]
CMD ["java", "-jar", "$APP_HOME/$ARTIFACT_NAME" ]
