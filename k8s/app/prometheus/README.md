##  Helmチャートのリポジトリを追加<br>

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
##  kube-prometheus-stackをhelmfileでdeployするための事前準備<br>
+   helmfileをインストール

　　  　   wget https://github.com/roboll/helmfile/releases/download/v0.140.0/helmfile_linux_amd64 -O helmfile
　　  　   chmod +x helmfile
　　  　   sudo mv helmfile /usr/local/bin/
　　      　helmfile version
