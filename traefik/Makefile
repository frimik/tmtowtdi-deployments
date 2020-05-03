build: all.yaml charts
	kustomize build

charts:
	helm dep build

all.yaml: charts
	helm template --release-name traefik --namespace ingress . > all.yaml

clean:
	rm -rfv all.yaml charts
