FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

# JAR 파일 복사
COPY build/libs/*.jar app.jar

# 포트 노출
EXPOSE 8085

ENTRYPOINT ["java", "-jar", "app.jar"]
