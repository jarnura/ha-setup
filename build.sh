echo "Starting docker build for image $1 and tag $2"

docker build -t $1:$2 .

echo "Finished building image $1:$2"

echo "Deleting older tar image"

rm ha-setup-k8.tar

echo "Deleted the old tar image"

docker image save -o ha-setup-k8.tar $1:$2

echo "Saved image in ha-setup-k8.tar"

ls | grep "ha-setup-k8"

echo "Load image to minikube"

minikube image load ha-setup-k8.tar 

grepimagename() {
  minikube image ls | grep "$1:$2"
}

imagepath=$(grepimagename $1 $2)
echo $imagepath

./replace_yaml.sh ./ha-setup-k8.yaml image $imagepath
