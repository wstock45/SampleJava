# heathcheck
Sample RestAPI, Git Action CI



# 1.  실행 테스트



```sh

$ curl localhost:8080/health -i


HTTP/1.1 200
Content-Type: text/plain;charset=UTF-8
Content-Length: 17
Date: Mon, 09 Sep 2024 03:33:43 GMT

Server is running


```



# 2.  Dockerizing





## 1) Docker build 및 실행

```sh




# Docker 빌드 명령
docker build -t my-spring-app .

# Docker 컨테이너 실행
docker run -p 8080:8080 my-spring-app

```

이제 http://localhost:8080/health에서 Spring Boot 애플리케이션을 확인할 수 있습니다.





## 2) [참고] 멀티 플랫폼 빌드

docker buildx를 사용하여 멀티 플랫폼 빌드를 지원하는 Docker 이미지를 생성할 수 있습니다. 다음 명령을 사용하여 이미지를 빌드합니다.

```sh
docker buildx build --platform linux/amd64,linux/arm64 -t my-spring-app:latest --push .


```

​	•	--platform linux/amd64,linux/arm64: 여러 플랫폼용으로 이미지를 빌드합니다 (멀티아키텍처 지원).

​	•	-t my-spring-app:latest: 생성된 Docker 이미지에 my-spring-app:latest 태그를 추가합니다.

​	•	--push: 빌드가 완료되면 이미지를 Docker Registry (예: Docker Hub)로 푸시합니다.

