# Use a specific Maven and JDK version
FROM maven:3.9.7-eclipse-temurin-11 AS build

# Set the working directory
WORKDIR /app

# Copy the project files
COPY . .

# Package the Spring Boot application
RUN mvn clean install -DskipTests

# Use the official OpenJDK image to run the app
FROM openjdk:11-jre-slim

#Create new user group(appgroup) and user(appuser)
RUN addgroup --gid 1000 appgroup
RUN adduser --home /home/appuser --uid 1005 --gid 1000 --disabled-password --gecos "" --shell /bin/bash appuser

# Set the working directory
WORKDIR /home/appuser

# Expose port 8080
EXPOSE 8080

#optional only for testing hpa
RUN apt-get update && apt-get install -y stress

# Copy the jar file from the build stage
COPY --from=build /app/target/*.jar app.jar

USER appuser

# Run the Spring Boot application
ENTRYPOINT ["java", "-jar", "app.jar"]
