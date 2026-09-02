# Build Stage
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

WORKDIR /app

# Copy pom.xml first to leverage Docker layer caching for dependencies
COPY pom.xml .

# Pre-fetch Maven dependencies
RUN mvn dependency:go-offline -B

# Copy source code and build production jar
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime Stage
FROM eclipse-temurin:17-jre-alpine

# Create non-root user for security best practices on Kubernetes/EKS
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy compiled jar from builder stage
COPY --from=builder /app/target/devops-springboot-project-1.0.0.jar app.jar

# Set ownership of application files
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose Spring Boot port
EXPOSE 8080

# Configure JVM flags optimized for container environments
ENTRYPOINT ["java", "-XX:+UseG1GC", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
