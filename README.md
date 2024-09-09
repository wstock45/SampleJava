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







# 3. [Buildx] **빌드 캐시 사용**

docker buildx는 빌드 캐시를 내보내고 가져오는 기능을 제공된다. 이 기능을 사용하면 빌드 속도를 크게 높일 수 있다.

예를 들어, 다음과 같이 캐시를 내보낼 수 있습니다

```sh

docker buildx build \
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

#### Build1

```sh
docker buildx build \
    --cache-from=type=registry,ref=ssongman/my-spring-app:cache \
    --cache-to=type=registry,ref=ssongman/my-spring-app:cache,mode=max \
    --push \
    -t ssongman/my-spring-app:latest .
    
```

* **캐시 가져오기**: --cache-from=type=registry,ref=myrepo/myimage:cache로 이전에 저장된 캐시를 레지스트리에서 가져옵니다.

* **캐시 저장**: --cache-to=type=registry,ref=myrepo/myimage:cache,mode=max로 빌드 후 최대한의 캐시 정보를 레지스트리에 저장합니다.

* **멀티 플랫폼 빌드**: --platform 플래그를 사용하여 다양한 아키텍처로 이미지를 빌드합니다.



#### Build2

Docker에서 buildx 명령을 사용하여 이미지를 빌드하고 푸시할 때, 기본적으로 빌드된 이미지는 로컬에 저장되지 않는다. 로컬에 이미지를 생성하려면 --load 또는 --output 옵션을 사용해야 한다.

```sh

# push, load 모두 사용
docker buildx build \
    --cache-from=type=registry,ref=ssongman/my-spring-app:cache \
    --cache-to=type=registry,ref=ssongman/my-spring-app:cache,mode=max \
    --push \
    --load \
    -t ssongman/my-spring-app:v1.1 .

# push 없이 load 만 : registry 에 push 는 안된다.
docker buildx build \
    --cache-from=type=registry,ref=ssongman/my-spring-app:cache \
    --cache-to=type=registry,ref=ssongman/my-spring-app:cache,mode=max \
    --load \
    -t ssongman/my-spring-app:v1.2 .
    
```

* --load 옵션은 멀티 플랫폼 빌드를 지원하지 않는다. 단일 플랫폼(--platform linux/amd64)에서만 작동한다.



#### 컨테이너 실행

```sh


# Docker 컨테이너 실행
$ docker run -p 8080:8080 ssongman/my-spring-app


# test
# 다른 터미널에서...
$ curl localhost:8080/health -i



```

