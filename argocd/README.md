# argocd

  This Kustomization installs [argo-cd](https://github.com/argoproj/argo-cd) and its basic requirements and patches things to:

- make application-controller not crash (ulimit -l)
- start argocd-server with `--insecure` argument
