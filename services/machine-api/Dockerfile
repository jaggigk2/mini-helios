# ---- Stage 1: build the jar with an official image that already has Maven + JDK 21 ----
FROM maven:3.9-eclipse-temurin-21 AS build
# work inside /app in the build container
WORKDIR /app
# copy the build recipe and the source code
COPY pom.xml ./
COPY src src
# build the runnable jar (-B = plain logs for a build server, -DskipTests = keep the lab fast)
RUN mvn -B -q package -DskipTests

# ---- Stage 2: small runtime image with only Java (no compiler, no source) ----
FROM eclipse-temurin:21-jre
# work inside /app
WORKDIR /app
# take only the finished jar from stage 1
COPY --from=build /app/target/*.jar app.jar
# document that the app listens on 8080 (Container Apps' --target-port)
EXPOSE 8080
# start the service
ENTRYPOINT ["java", "-jar", "app.jar"]