FROM openjdk:12-jdk-alpine as build-step
WORKDIR /workspace
COPY build.gradle settings.gradle gradlew /workspace/
COPY gradle/ /workspace/gradle/
# RUN ./gradlew resolveDependencies
COPY . /workspace
RUN ./gradlew bootJar

FROM openjdk:12-alpine
RUN apk add bash
COPY --from=build-step /workspace/build/libs/aaddemo-0.0.1-SNAPSHOT.jar /aaddemo.jar
COPY prepare.sh /prepare.sh
ENV PROFILE docker
EXPOSE 8080
ENTRYPOINT ["/prepare.sh"]
CMD ["java", "-jar", "aaddemo.jar"]
