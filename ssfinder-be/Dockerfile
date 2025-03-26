FROM openjdk:17
WORKDIR /app
COPY build/libs/ssfinder-be-0.0.1-SNAPSHOT.jar ssfinder-be.jar
EXPOSE 8080
RUN ln -snf /usr/share/zoneinfo/Asia/Seoul /etc/localtime && \
    echo "Asia/Seoul" > /etc/timezone
CMD ["java", "-jar", "ssfinder-be.jar"]
