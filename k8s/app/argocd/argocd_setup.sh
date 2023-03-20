# region : create update.sh

kubectl create namespace argocd
sleep 10
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
sleep 10
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
