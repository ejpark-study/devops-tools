# My Devops Tools (Environments): with Kubernetes

쿠버네티스 환경에서 어플리케이션을 개발하고, 개발된 어플리케이션을 서비스하는 환경을 구축하는 방법에 관한 문서이다.
(2022년 KANS 1기 스터디(HTTP://KANS.CloudNeta.net) **중간 과제**로 작성한다. 이후 랩 스터디 자료로 사용할 예정이다.)

![img.png](images/2022-02-03T1450.png)

* Application Development Flow
  * 어플리케이션을 개발해서 gitlab 에 업로드 하면, goCD 가 코드를 받아서 도커 이미지로 빌드 한다. 
  * 빌드된 이미지를 harbor 에 푸시 하면 argoCD가 받아서 쿠버네티스에 배포 한다. 
  * 운영중 생기는 어플리케이션 로그는 Elasticsearch 에 저장 하고, 저장된 로그를 Kibana Dashboard 로 확인 한다.

※ OpenEBS 를 제외한 여러 조합으로 실험해 봤는데, (DB 와 같이) 상태가 있어야 하는 서비스는 docker 혹은 docker-compose 로 실행하고, 어플리케이션만 상태 없이 쿠버네티스로 실행한다.

## [사전 작업] Powershell + Windows terminal + Oh my posh + Nerd Fonts

![img.png](images/2022-02-03T1427.png)

1) windows terminal 설치

* https://docs.microsoft.com/en-us/windows/terminal/install 에서 터미널을 설치한다.

3) Oh my posh 설치

```powershell
Install-Module posh-git -Scope CurrentUser -Force
Install-Module oh-my-posh -Scope CurrentUser -Force
Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck
Install-Module -Name Terminal-Icons -Repository PSGallery
```

4) Nerd Fonts 설치

* https://www.nerdfonts.com/ 에서 폰트를 다운로드해서 압축을 해제한다.
* 폰트를 설택후 마우스 오른쪽 클릭해서 '설치'를 선택한다.

6) windows terminal 폰트 변경

* 'Ctrl + ,' -> '프로필/기본값/모양/글꼴' -> 'DejaVuSansMono Nerd Font Mono' 선택 (4 에서 설치한 폰트 이름, 고정폭 폰트(Mono)를 선택한다.)

8-1) $PROFILE 생성 혹은 수정

```powershell
code $PROFILE
```

8-2) 아래와 같이 설정

```powershell
Set-Alias mpa multipass
Set-Alias vg vagrant
Set-Alias vbox VBoxManage

Import-Module posh-git
Import-Module oh-my-posh
Import-Module Terminal-Icons

Set-PSReadLineOption -PredictionSource History

Set-PoshPrompt -Theme paradox
```

## vagrant + kubernetes (1 master + 2 worker)

1) kubernetes 클러스터 생성

```powershell
cd vagrant\
vagrant up
```

2) virtualbox image 를 package 로 변환

```powershell
❯ VBoxManage list vms
"ubuntu-focal-20.04-cloudimg-20220104_1642837486794_58463" {63ed7399-f34c-4372-ae96-395e19ef7deb}
"master" {1a493330-770e-4ae0-9b43-22b25723144d}
"worker1" {9b95129a-fcb6-489c-9399-b831ae44a11c}
"worker2" {67af84d2-6c61-404b-b9c6-017d4fe8bd25}

vagrant package --base 1a493330-770e-4ae0-9b43-22b25723144d --output master.box
vagrant package --base 9b95129a-fcb6-489c-9399-b831ae44a11c --output worker1.box
vagrant package --base 67af84d2-6c61-404b-b9c6-017d4fe8bd25 --output worker2.box
```

## [kubernetes] network plugin

* flannel: https://github.com/flannel-io/flannel

```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

* calico: https://www.calicolabs.com/
  * https://cwal.tistory.com/12

```bash
curl -O https://docs.projectcalico.org/archive/v3.17/manifests/calico.yaml
kubectl apply -f calico.yaml
```

* cilium

```bash
cilium install
```

## [kubernetes] metric server

metrics-server.yaml 파일의 134 번째 라인에 '--kubelet-insecure-tls'를 추가한다.

```bash
wget -O metrics-server.yaml https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

vim +134 metrics-server.yaml
     - args:
        - --kubelet-insecure-tls

kubectl apply -f metrics-server.yaml
```

## [kubernetes] ingress-controller

```bash
wget -O ingress-controller.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/deploy.yaml

#ingress-controller.yaml 에서 LoadBancer 옵션으로 변경한다.

kubectl apply -f ingress-controller.yaml
```

## [docker] gitlab

1) gitlab 용 certs 생성

* https://docs.microsoft.com/ko-kr/azure/aks/ingress-own-tls
 
```bash
DNS_NAME=mydomain.com
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -subj "/CN=${DNS_NAME}/O=${DNS_NAME}-tls" \
    -out ${DNS_NAME}.crt -keyout ${DNS_NAME}.key

sudo mkdir -p /data/gitlab/config/ssl /data/gitlab-runner/config/certs

sudo cp ${DNS_NAME}.* /data/gitlab/config/ssl
sudo cp ${DNS_NAME}.* /data/gitlab-runner/config/certs
```

2) gitlab 실행 스크립트

* https://twoseed.atlassian.net/wiki/spaces/OPS/pages/551256065/GitLab+Docker+Engine+-+Ubuntu+18.04

```bash
cat <<EOS | tee gitlab.sh 
#!/usr/bin/env bash

DNS_NAME=mydomain.com
GITLAB_ROOT_PASSWORD=mypassword

docker stop gitlab
docker rm gitlab

docker run \\
  --detach --restart always \\
  --name gitlab \\
  --hostname gitlab \\
  --publish 80:80 \\
  --publish 443:443 \\
  --add-host ${DNS_NAME}:172.19.178.114 \\
  --env GITLAB_OMNIBUS_CONFIG="external_url 'https://${DNS_NAME}/'; gitlab_rails['lfs_enabled'] = true; letsencrypt['enable'] = false;" \\
  --env GITLAB_ROOT_PASSWORD="${GITLAB_ROOT_PASSWORD}" \\
  --env GITLAB_TIMEZONE="Asia/Seoul" \\
  --volume /data/gitlab/config:/etc/gitlab \\
  --volume /data/gitlab/logs:/var/log/gitlab \\
  --volume /data/gitlab/data:/var/opt/gitlab \\
  gitlab/gitlab-ce:14.4.2-ce.0

docker logs -f gitlab
EOS

chmod +x gitlab.sh

docker exec -it gitlab /bin/bash
```

3-1) gitlab-runner 실행 스크립트 생성

```bash
cat <<EOS | tee gitlab-runner.sh 
#!/usr/bin/env bash

DNS_NAME=mydomain.com

docker stop gitlab-runner
docker rm gitlab-runner

docker run \\
    --detach --restart always \\
    --name gitlab-runner \\
    --hostname gitlab-runner \\
    --privileged \\
    --network host \\
    --add-host mirror.kakao.com:113.29.189.165 \\
    --add-host registry.npmjs.org:104.16.23.35 \\
    --add-host ${DNS_NAME}:172.0.0.10 \\
    --volume /var/run/docker.sock:/var/run/docker.sock \\
    --volume /data/gitlab-runner/config:/etc/gitlab-runner \\
    gitlab/gitlab-runner:latest

docker logs -f gitlab-runner
EOS

chmod +x gitlab-runner.sh
```

3-2) gitlab-runner register (with docker sock)

* https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3748

```bash
DNS_NAME=mydomain.com
REG_TOKEN=$(awk -v cmd='openssl x509 -noout -subject' '/BEGIN/{close(cmd)};{print | cmd}' < /etc/ssl/certs/ca-certificates.crt)

docker exec -it gitlab-runner \
  gitlab-runner register \
    --non-interactive \
    --name runner \
    --url https://${DNS_NAME} \
    --registration-token ${REG_TOKEN} \
    --executor "docker" \
    --docker-image alpine:latest \
    --run-untagged \
    --locked="false" \
    --docker-privileged \
    --docker-pull-policy if-not-present \
    --docker-network-mode host \
    --docker-extra-hosts mirror.kakao.com:113.29.189.165 \
    --docker-extra-hosts registry.npmjs.org:104.16.23.35 \
    --add-host ${DNS_NAME}:172.0.0.10 \
    --docker-network-mode host \
    --docker-volumes '/var/run/docker.sock:/var/run/docker.sock'
```

## [docker-compose] harbor

* [[DevOps] Docker-Compose를 이용해 Harbor 배포하기(HTTPS 지원)](https://wookiist.dev/126)
* [Deploy Harbor with the Quick Installation Script](https://goharbor.io/docs/2.0.0/install-config/quick-install-script/)

0) install docker compose 설치 

* [docker/compose/releases](https://github.com/docker/compose/releases)

```bash
wget https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64
sudo mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose

docker-compose version
```

1) harbor 용 certs 생성: mydomain.com 인증서 생성

```bash
DNS_NAME=mydomain.com
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -subj "/CN=${DNS_NAME}/O=${DNS_NAME}-tls" \
    -out ${DNS_NAME}.crt -keyout ${DNS_NAME}.key

sudo mkdir -p /data/harbor/certs

sudo mv ${DNS_NAME}.* /data/harbor/certs/
```

2) harbor repo 다운로드 

* https://goharbor.io/docs/2.0.0/install-config/
* [harbor/releases](https://github.com/goharbor/harbor/releases)
* [harbor 설치 부터 kubernetes 연동까지! – lahuman](https://lahuman.github.io/kubernetes-harbor/)

> download release file: harbor-offline-installer-v1.10.10.tgz

3) harbor config 설정 (v1.10.10 기준)
 
* harbor.yml

> hostname: harbor 도메인 주소
> 
> harbor_admin_password: admin 패스워드
> 
> data_volume: docker image 저장 위치

```yaml
# Configuration file of Harbor

# The IP address or hostname to access admin UI and registry service.
# DO NOT use localhost or 127.0.0.1, because Harbor needs to be accessed by external clients.
hostname: mydomain.com

# https related config
https:
  # https port for harbor, default is 443
  port: 5000
  # The path of cert and key files for nginx
  certificate: /data/harbor/certs/mydomain.com.crt
  private_key: /data/harbor/certs/mydomain.com.key

harbor_admin_password: mypassword

# Harbor DB configuration
database:
  # The password for the root user of Harbor DB. Change this before any production use.
  password: mypassword

# The default data volume
data_volume: /data/harbor
```

4) harbor 설치

```bash
sudo ./install.sh
```

5) kubernetes 용 docker pull secret 생성 방법

* kubernetes Secret을 생성하는 여러 방법이 있으나, 에러 나는 경우가 많다. 계정을 robot secret 으로 생성하는 경우 아이디가 robot$ 로 시작하는데, 이때 $가 말성을 부린다. 그래서 docker login 후 ~/.docker/config.json 파일을 kubernetes Secret 으로 생성한다.

```bash
❯ docker login mydomain.com:5000
Username: admin
Password: **********
WARNING! Your password will be stored unencrypted in ~/.docker/config.json.

Login Succeeded

❯ kubectl create secret generic harbor-secret \
    --from-file=.dockerconfigjson=~/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
    
❯ kubectl get secret/harbor-secret --output=yaml > helm/template/Secret.yaml

❯ kubectl delete secret/harbor-secret
```

## [docker] minio

1) minio docker scripts 생성

```bash
cat <<EOS | tee minio.sh 
#!/usr/bin/env bash

docker stop minio
docker rm minio

docker run \\
  -d --restart always \\
  --name minio \\
  --hostname minio \\
  -p 9001:80 \\
  -p 9000:9000 \\
  -v "/data/minio:/data:rw" \\
  -e "MINIO_ROOT_USER=admin" \\
  -e "MINIO_ROOT_PASSWORD=mypassword" \\
  -v /etc/timezone:/etc/timezone:ro \\
  -v /etc/localtime:/etc/localtime:ro \\
  minio/minio:latest \\
    server --address "0.0.0.0:9000" --console-address "0.0.0.0:80" /data

docker logs -f minio
EOS

chmod +x minio.sh
```

2) minio client 설치

```bash
wget https://dl.min.io/client/mc/release/linux-amd64/mc 
chmod +x mc && sudo mv mc /usr/local/bin/mc

mc alias set wst http://mydomain.com:9000 admin mypassword
mc alias list
```

## [kubernetes] goCD

* https://www.gocd.org/download/#helm

```bash
helm repo add gocd https://gocd.github.io/helm-chart

kubectl create ns gocd
helm install gocd gocd/gocd --namespace gocd
```

## [kubernetes] argoCD

* https://www.arthurkoziel.com/setting-up-argocd-with-helm/

1) argo helm install

```bash
helm repo add argo-cd https://argoproj.github.io/argo-helm
helm dep update charts/argo-cd/

helm install argo-cd charts/argo-cd/
```

2) web ui

```bash
kubectl port-forward svc/argo-cd-argocd-server 8080:443

# init admin password
kubectl get pods -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
```

## [docker] Elasticsearch + Kibana + Logstash
> 작성중
