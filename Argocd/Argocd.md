Getting started with ArgoCD

1. Install Argo CD

kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

This will create a new argocd namespace where all Argo CD services and application resources will reside. 
It will also install Argo CD by applying the official manifests from the stable branch.

2. Argo CD CLI Installation on linux :
   curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

3. Access Argo CD
By default, Argo CD isn’t exposed outside the cluster. To access Argo CD from your browser or CLI, use one of the following methods:

Service Type Load Balancer
Change the argocd-server service type to LoadBalancer:

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
After a short wait, your cloud provider will assign an external IP address to the service.

kubectl get svc argocd-server -n argocd ( used to get argocd access url ) 

4. Go to ArgoCD UI and login :
   USER : admin
   Command to fetch argocd password :
   argocd admin initial-password -n argocd

5. Add your git repository under setting.

6. Add your k8 Cluster on Argo CD from CLI
   Login to ArgoCD on CLI

   Command :
   argocd login <argocd url>

   First list all clusters contexts in your current kubeconfig:


kubectl config get-contexts -o name
Choose a context name from the list and supply it to argocd cluster add CONTEXTNAME. 

For example, for docker-desktop context, run:
argocd cluster add docker-desktop

7. Create Application on ArgoCD and apply changes. 

   

