FROM openjdk:12-jdk-alpine as gradle
WORKDIR /app
RUN apk add --update bash curl
COPY gradlew /app/
COPY gradle/ /app/gradle/
RUN chmod +x gradlew && \
    ./gradlew bootJar || return 0

FROM gradle as build
WORKDIR /app
COPY build.gradle settings.gradle /app/
COPY src/ /app/src/
RUN ./gradlew bootJar

FROM openjdk:12-alpine
RUN apk add bash
WORKDIR /app
COPY --from=build /app/build/libs/aaddemo-0.0.1-SNAPSHOT.jar /app/aaddemo.jar
COPY prepare.sh /app/prepare.sh
RUN chmod +x /app/prepare.sh
ENV PROFILE docker
EXPOSE 8080
ENTRYPOINT ["/app/prepare.sh"]
CMD ["java", "-jar", "/app/aaddemo.jar"]
