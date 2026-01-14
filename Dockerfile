# Multi-stage build for minimal image size (< 150MB)
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app

# Copy Maven wrapper and pom.xml
COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .

# Download dependencies (cached layer)
RUN ./mvnw dependency:go-offline -B || true

# Copy source code
COPY src ./src

# Build application
RUN ./mvnw clean package -DskipTests -B

# Create minimal JRE using jlink with all required modules for Spring Boot
RUN jlink \
    --add-modules java.base,java.logging,java.xml,java.desktop,java.management,java.naming,java.instrument,java.sql,java.prefs,jdk.unsupported \
    --strip-debug \
    --no-man-pages \
    --no-header-files \
    --compress=2 \
    --output /javaruntime

# Final stage - minimal runtime image
FROM alpine:3.18

WORKDIR /app

# Install minimal runtime dependencies
RUN apk add --no-cache \
    libc6-compat \
    && rm -rf /var/cache/apk/* /tmp/*

# Copy custom minimal JRE from builder
COPY --from=builder /javaruntime /javaruntime

# Copy built JAR from builder
COPY --from=builder /app/target/*.jar app.jar

# Create non-root user
RUN addgroup -S spring && adduser -S spring -G spring && \
    chown spring:spring app.jar

USER spring:spring

EXPOSE 8080

ENV JAVA_HOME=/javaruntime
ENV PATH="${JAVA_HOME}/bin:${PATH}"

ENTRYPOINT ["java", "-jar", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "app.jar"]
