# Stage 1: Build the application using Maven
FROM maven:3.8.5-openjdk-17-slim AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the pom.xml and download the dependencies
COPY pom.xml ./
RUN mvn dependency:go-offline

# Copy the entire source code
COPY src ./src

# Package the application
RUN mvn clean package -DskipTests

# Stage 2: Create a smaller, final image
FROM openjdk:17-jdk-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the JAR file from the build stage
COPY --from=build /app/target/healthcheck*.jar /app/healthcheck.jar

# Expose the application port
EXPOSE 8080

# Define the command to run the application
CMD ["java", "-jar", "/app/healthcheck.jar"]