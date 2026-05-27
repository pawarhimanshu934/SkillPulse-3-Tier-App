# MySQL Database Initialization in Kubernetes

This document explains the mechanism used to initialize the database schema and seed data for the **SkillPulse** application inside the Kubernetes cluster.

---

## 1. What does this block do?

In [10-statefulSet.yml](file:///home/ubuntu/SkillPulse-3-Tier-App/kubernetes/10-statefulSet.yml), we configure a ConfigMap volume and mount it into the MySQL container:

```yaml
        volumeMounts:
        - name: mysql-init-volume
          mountPath: /docker-entrypoint-initdb.d
      volumes:
      - name: mysql-init-volume
        configMap:
          name: mysql-init-configmap
```

* **`mysql-init-configmap`**: A Kubernetes ConfigMap defined in [12-mysql-init-configmap.yml](file:///home/ubuntu/SkillPulse-3-Tier-App/kubernetes/12-mysql-init-configmap.yml) that contains the SQL schema definition and demo seed data (the raw content of `mysql/init.sql`).
* **`/docker-entrypoint-initdb.d`**: The official MySQL Docker image is built with an entrypoint bootstrap script. On the very first startup of the container—when the database storage directory `/var/lib/mysql` is completely empty—this entrypoint script automatically scans `/docker-entrypoint-initdb.d` and executes any `.sql` scripts it finds.

---

## 2. Why is this critical?

Without this volume mounting, the following will occur:

1. **Successful connection, but empty database**: The Go backend will successfully establish a TCP/IP connection to the MySQL StatefulSet pod (since the credentials and database are still created by environment variables).
2. **App fails on any database query**: As soon as any user loads the dashboard or lists skills, the Go API makes SQL queries (like `SELECT * FROM skills;`).
3. **Database errors**: Because the tables `skills` and `learning_logs` were never created, MySQL will return a standard SQL error:
   ```
   Error 1146 (42S02): Table 'skillpulse.skills' doesn't exist
   ```
   This will cause the frontend to fail to render any data and the application to break.

---

## 3. How to re-initialize cleanly

MySQL only runs the files in `/docker-entrypoint-initdb.d` if the `/var/lib/mysql` data directory is **completely empty**. 

If you modify the SQL schema or seed data and want it to take effect on a running cluster:
1. Delete the MySQL StatefulSet.
2. Delete the associated PersistentVolumeClaims (PVCs) to clear the existing data volumes:
   ```bash
   kubectl delete statefulset skillpulse-statefulset -n skillpulse-ns
   kubectl delete pvc -l app=mysql -n skillpulse-ns
   ```
3. Apply the updated manifests to trigger a clean recreation:
   ```bash
   kubectl apply -f 12-mysql-init-configmap.yml -f 10-statefulSet.yml -n skillpulse-ns
   ```
