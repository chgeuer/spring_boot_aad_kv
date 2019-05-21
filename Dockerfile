FROM openjdk:12-jdk-alpine as build
WORKDIR /app
COPY build.gradle settings.gradle gradlew /app/
COPY gradle/ /app/gradle/
RUN ./gradlew build || return 0
COPY . /app/
RUN ./gradlew bootJar

FROM openjdk:12-alpine
RUN apk add bash
WORKDIR /app
COPY --from=build /app/build/libs/aaddemo-0.0.1-SNAPSHOT.jar /app/aaddemo.jar
COPY prepare.sh /app/prepare.sh
ENV PROFILE docker
EXPOSE 8080
ENTRYPOINT ["/app/prepare.sh"]
CMD ["java", "-jar", "/app/aaddemo.jar"]
