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



## 1) Dockerfile

```yaml
# Stage 1: Build the application using Maven
FROM maven:3.8.4-openjdk-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests


# Stage 2: Run the application using OpenJDK
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

```







## 2) Docker build 및 실행

```sh

# Docker 빌드 명령
$ docker build -t my-spring-app .


# Docker 컨테이너 실행
$ docker run -p 8080:8080 my-spring-app


# test
# 다른 터미널에서...
$ curl localhost:8080/health -i


```

이제 http://localhost:8080/health에서 Spring Boot 애플리케이션을 확인







# 3. Docker Buildx





## 1) Docker Buildx란?



**Docker Buildx**는 Docker의 확장 기능으로, 기본 빌드 명령어보다 더 강력한 빌드 기능을 제공합니다. Buildx는 다음과 같은 기능을 포함합니다:



* **멀티 플랫폼 빌드**: 하나의 Dockerfile로 여러 플랫폼에 맞는 이미지를 동시에 빌드.
* **외부 빌더(Builder)**: 로컬에서 직접 빌드하지 않고도 외부 클러스터를 통해 빌드 작업을 수행.
* **캐시 내보내기/가져오기**: 빌드 캐시를 내보내고 가져와 빌드 속도를 높임.



# 2) [Buildx] 멀티 플랫폼 빌드

docker buildx를 사용하여 멀티 플랫폼 빌드를 지원하는 Docker 이미지를 생성할 수 있다. 



## (1) **멀티 플랫폼 빌드가 필요한 이유**

오늘날 다양한 하드웨어 아키텍처가 사용되면서, 멀티 플랫폼 지원이 중요해졌다. 특히, 서버에서는 대부분 **x86_64** 기반이지만, 모바일 기기나 일부 개발 환경에서는 **ARM** 기반의 아키텍처도 사용된다. 애플의 M1/M2 칩은 ARM 기반이기 때문에, ARM 아키텍처를 지원하는 Docker 이미지를 빌드할 필요가 있다.

멀티 플랫폼 빌드는 이러한 문제를 해결하고, 애플리케이션이 다양한 플랫폼에서 실행될 수 있도록 한다.



## (2) 빌더 활성화

```sh

$ docker buildx create --use
upbeat_matsumoto


$ docker buildx  ls
NAME/NODE               DRIVER/ENDPOINT     STATUS     BUILDKIT   PLATFORMS
upbeat_matsumoto*       docker-container
 \_ upbeat_matsumoto0    \_ desktop-linux   inactive
default                 docker
 \_ default              \_ default         running    v0.13.2    linux/arm64, linux/amd64, linux/amd64/v2, linux/riscv64, linux/ppc64le, linux/s390x, linux/386, linux/mips64le, linux/mips64, linux/arm/v7, linux/arm/v6
desktop-linux           docker
 \_ desktop-linux        \_ desktop-linux   running    v0.13.2    linux/arm64, linux/amd64, linux/amd64/v2, linux/riscv64, linux/ppc64le, linux/s390x, linux/386, linux/mips64le, linux/mips64, linux/arm/v7, linux/arm/v6
 

```



## (3) **멀티 플랫폼 빌드 실행**

```sh

docker buildx build --platform linux/amd64,linux/arm64 -t my-spring-app:latest --push .

```

* --platform linux/amd64,linux/arm64: 여러 플랫폼용으로 이미지를 빌드 (멀티아키텍처 지원).
* -t my-spring-app:latest: 생성된 Docker 이미지에 my-spring-app:latest 태그를 추가
* --push: 빌드가 완료되면 이미지를 Docker Registry (예: Docker Hub)로 푸시
  * push 옵션은 필수이다.
  * 없으면 아래와 같은 에러 발생
    * No output specified with docker-container driver. Build result will only remain in the build cache. To push result image into registry use --push or to load image into docker use --load



## (4) 확인

멀티 플랫폼 빌드가 완료되면, docker manifest inspect 명령어로 이미지가 여러 아키텍처로 빌드되었는지 확인할 수 있다

```sh

docker manifest inspect my-spring-app:latest

```





# 3) [Buildx] **빌드 캐시 사용**

docker buildx는 빌드 캐시를 내보내고 가져오는 기능을 제공된다. 이 기능을 사용하면 빌드 속도를 크게 높일 수 있다.

예를 들어, 다음과 같이 캐시를 내보낼 수 있습니다

```sh

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myapp:latest \
  --push \
  --cache-to=type=inline \
  --cache-from=type=registry,ref=myapp:cache .


```

이전 빌드의 캐시를 재사용하여 빌드 시간을 단축할 수 있다.



## (1) **빌드 캐시 저장 옵션**

* **local**: 로컬 파일 시스템에 캐시를 저장합니다.
  * 예시: --cache-to=type=local,dest=/path/to/cache

* **inline**: 이미지에 캐시 메타데이터를 내장시킵니다. 이 방식은 이미지 자체에 캐시 정보를 저장하므로, 다른 환경에서도 이미지를 가져올 때 캐시를 사용할 수 있습니다.
  * 예시: --cache-to=type=inline

* **registry**: Docker 레지스트리에 캐시를 저장합니다. 이 방식은 레지스트리 기반의 빌드 환경에서 유용합니다.
  * 예시: --cache-to=type=registry,ref=myrepo/myimage:cache

* **s3**: AWS S3와 같은 외부 스토리지에 캐시를 저장할 수 있습니다.
  * 예시: --cache-to=type=s3,bucket=mybucket,region=us-west-2





## (2) 캐시 최적화 옵션**

캐시를 저장할 때 mode 옵션을 통해 캐시 크기를 제어할 수 있다.

* min: 필요한 최소한의 캐시만 저장

* max: 가능한 모든 캐시 데이터를 저장하여, 최대한 많은 빌드 데이터를 재사용할 수 있도록 한다.



## (3) 실제 사용

```sh
docker buildx build \
    --cache-from=type=registry,ref=myrepo/myimage:cache \
    --cache-to=type=registry,ref=myrepo/myimage:cache,mode=max \
    -t myrepo/myimage:latest .
    
```

* **캐시 가져오기**: --cache-from=type=registry,ref=myrepo/myimage:cache로 이전에 저장된 캐시를 레지스트리에서 가져옵니다.

* **캐시 저장**: --cache-to=type=registry,ref=myrepo/myimage:cache,mode=max로 빌드 후 최대한의 캐시 정보를 레지스트리에 저장합니다.

* **멀티 플랫폼 빌드**: --platform 플래그를 사용하여 다양한 아키텍처로 이미지를 빌드합니다.
