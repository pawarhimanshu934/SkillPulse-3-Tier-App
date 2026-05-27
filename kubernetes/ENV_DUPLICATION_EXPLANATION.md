# Environment Variable Duplication in Kubernetes ConfigMap & Secret

This document explains why there are duplicate keys (e.g. `DB_USER` vs. `MYSQL_USER`) inside [02-configMap.yml](file:///home/ubuntu/SkillPulse-3-Tier-App/kubernetes/02-configMap.yml) and [03-secret.yml](file:///home/ubuntu/SkillPulse-3-Tier-App/kubernetes/03-secret.yml), and how to remove this duplication.

---

## 1. Why is there duplication?

Our application consists of two different containers that read configurations differently:

1. **Go Backend Container**:
   * Expects environment variables named: `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_NAME`, and `DB_PASSWORD`.
   * These are hardcoded in the Go application code (e.g., `backend/database/db.go`).
2. **Official MySQL Container**:
   * Expects environment variables named: `MYSQL_ROOT_PASSWORD`, `MYSQL_USER`, `MYSQL_DATABASE`, and `MYSQL_PASSWORD`.
   * These are hardcoded in the entrypoint scripts of the official `mysql:8.4` Docker image to automatically create the database and user on first start.

Because we use `envFrom` in our deployment manifests, Kubernetes injects all keys as-is directly into the containers. Therefore, we must define both sets of variable names.

---

## 2. How to remove the duplication (Recommended approach)

If you want to keep the ConfigMap and Secret dry and clean, you can define the values only once, and map them explicitly using `valueFrom` in the MySQL StatefulSet manifest.

### Step 1: Clean up ConfigMap (`02-configMap.yml`)
Keep only one set of keys:
```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: mysql-config
  namespace: skillpulse-ns
data:
  DB_HOST: mysql-service
  DB_PORT: "3306"
  DB_USER: skillpulse
  DB_NAME: skillpulse
```

### Step 2: Clean up Secret (`03-secret.yml`)
Keep only one set of keys:
```yaml
kind: Secret
apiVersion: v1
metadata:
  name: mysql-secret
  namespace: skillpulse-ns
type: Opaque
data:
  MYSQL_ROOT_PASSWORD: cm9vdHBhc3N3b3JkMTIz
  DB_PASSWORD: c2tpbGxwdWxzZTEyMw==
```

### Step 3: Map keys explicitly in StatefulSet (`10-statefulSet.yml`)
Instead of using `envFrom` in the MySQL container definition, map the variables individually:
```yaml
    spec:
      containers:
      - name: mysql-container
        image: mysql:8.4
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_ROOT_PASSWORD
        - name: MYSQL_USER
          valueFrom:
            configMapKeyRef:
              name: mysql-config
              key: DB_USER
        - name: MYSQL_DATABASE
          valueFrom:
            configMapKeyRef:
              name: mysql-config
              key: DB_NAME
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: DB_PASSWORD
```
This decouples ConfigMap/Secret storage from individual container expectations, eliminating any duplicated configurations!
