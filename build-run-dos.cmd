@echo off

call gradlew.bat bootJar

java -jar build\libs\aaddemo-0.0.1-SNAPSHOT.jar
