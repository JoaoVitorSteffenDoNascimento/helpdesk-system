FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -q dependency:go-offline -DexcludeTransitiveDependencies
COPY src ./src
RUN mvn -q clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -g 1000 appuser && adduser -D -u 1000 -G appuser appuser
COPY --from=build --chown=appuser:appuser /app/target/user-service-0.0.1-SNAPSHOT.jar app.jar
USER appuser
EXPOSE 8082
ENTRYPOINT exec java $JAVA_OPTS -jar app.jar
