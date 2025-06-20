# Flask Secret Demo on Kubernetes (k3s) with Simulated CyberArk Push-to-File

This project demonstrates a simple Flask web app deployed in a lightweight Kubernetes (k3s) cluster on an EC2 instance. The app retrieves a secret from a host-mounted file, simulating CyberArk Conjur’s push-to-file model.

---

## ✅ Environment

- Ubuntu EC2 instance (static IP / DNS)
- Kubernetes via [k3s](https://k3s.io)
- Flask app running in a pod
- Secret injected via hostPath volume
- Kubernetes Dashboard for UI access

---

## 🚀 Setup Steps

### 1. Install k3s

```bash
curl -sfL https://get.k3s.io | sh -
```

Set up `kubectl`:

```bash
mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

### 2. Deploy Kubernetes Dashboard

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

#### Create Admin User

**dashboard-admin-user.yaml**:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
```

```bash
kubectl apply -f dashboard-admin-user.yaml
```

---

### 3. Create Static Admin Token

**admin-user-token.yaml**:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: admin-user-token
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: admin-user
type: kubernetes.io/service-account-token
```

```bash
kubectl apply -f admin-user-token.yaml
sleep 10
kubectl -n kubernetes-dashboard get secret admin-user-token -o go-template='{{.data.token | base64decode}}'
```

---

### 4. Expose the Dashboard via NodePort

```bash
kubectl -n kubernetes-dashboard edit svc kubernetes-dashboard
```

Change:

```yaml
type: ClusterIP
```

to:

```yaml
type: NodePort
```

Open the NodePort (e.g. `31488`) in your EC2 Security Group.

Access:

```
https://<your-ec2-public-dns>:31488
```

Login using the static token.

---

### 5. Simulate CyberArk Secret File

```bash
sudo mkdir -p /opt/conjur
echo "CyberArkSecretDemoValue123!" | sudo tee /opt/conjur/conjur-secret.txt > /dev/null
sudo chmod 600 /opt/conjur/conjur-secret.txt
```

---

### 6. Flask App Code

**app.py**:

```python
from flask import Flask

app = Flask(__name__)

@app.route("/")
def index():
    try:
        with open("/secrets/conjur-secret.txt", "r") as f:
            secret = f.read().strip()
    except Exception as e:
        secret = f"Error reading secret: {e}"
    return f"<h1>Retrieved Secret</h1><p>{secret}</p>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

---

### 7. Dockerfile

**Dockerfile**:

```dockerfile
FROM python:3.10-slim

WORKDIR /app
COPY app.py .
RUN pip install flask
CMD ["python", "app.py"]
```

Build and save the image:

```bash
docker build -t flask-secret-app:latest .
docker save -o flask-secret-app.tar flask-secret-app:latest
sudo k3s ctr images import flask-secret-app.tar
```

---

### 8. Deploy to Kubernetes

**flask-secret-app.yaml**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-secret-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flask-secret
  template:
    metadata:
      labels:
        app: flask-secret
    spec:
      containers:
        - name: flask
          image: flask-secret-app:latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 5000
          volumeMounts:
            - name: conjur-secret
              mountPath: /secrets/conjur-secret.txt
              readOnly: true
      volumes:
        - name: conjur-secret
          hostPath:
            path: /opt/conjur/conjur-secret.txt
            type: File

---
apiVersion: v1
kind: Service
metadata:
  name: flask-secret-svc
spec:
  selector:
    app: flask-secret
  type: NodePort
  ports:
    - port: 80
      targetPort: 5000
      nodePort: 31333
```

Apply and restart pod:

```bash
kubectl apply -f flask-secret-app.yaml
kubectl delete pod -l app=flask-secret
```

---

### 9. Access the Flask App

Open port `31333` in your EC2 security group.

Then go to:

```plaintext
http://<your-ec2-public-dns>:31333
```

Expected output:

```
Retrieved Secret
CyberArkSecretDemoValue123!
```

---

## ✅ Optional Enhancements

- 📦 Reload secrets dynamically
- 🔐 Ingress controller with TLS and authentication
- 🧰 Replace hostPath with CSI + sidecar for live Conjur demo

---

## 🛡️ Security Notes

- Static tokens are fine for testing, not production.
- Use Kubernetes Secrets or CSI drivers for real-world scenarios.
- Never expose NodePorts publicly in production without access controls.

---

## 🔗 References

- [k3s.io](https://k3s.io)
- [Kubernetes Dashboard](https://github.com/kubernetes/dashboard)
- [CyberArk Conjur](https://www.cyberark.com/products/conjur/)
