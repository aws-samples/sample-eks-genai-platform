terraform init
terraform apply -auto-approve -var-file=dev.tfvars
$(terraform output -raw configure_kubectl)