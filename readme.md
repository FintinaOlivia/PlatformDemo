kind delete cluster --name platform
kubectl get nodes

kubectl cluster-info
kubectl get nodes


kubectl get pods

trivy image \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  platform-demo:test

docker buildx build \
  --load \
  -t platform-demo:test \
  .

docker tag platform-demo:test localhost:5001/platform-demo:test
docker push localhost:5001/platform-demo:test


kubectl apply -f k8s/

kubectl get pods
kubectl get service

========== Health Check ============
kubectl port-forward service/platform-demo 8081:8080
curl http://localhost:8081/health

================================================

Jenkins Config

sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube

sudo -u jenkins kubectl get nodes

- this is not fine for prroduction env, research this later

===============================================

sudo -u jenkins docker buildx version

docker volume create jenkins_home
docker run -d \
  --name jenkins \
  -p 8085:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts


===========================================
JENKINS CREDENTIALS:
Username: registry-user
Password: registry
ID: local-registry
Description: Local Docker registry