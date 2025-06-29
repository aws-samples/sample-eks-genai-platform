resource "null_resource" "create_nodepools_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/../auto-mode-config/nodepools"
  }
}

resource "local_file" "setup_graviton" {
  content = templatefile("${path.module}/../auto-mode-config/nodepool-templates/graviton-nodepool.yaml.tpl", {
    node_iam_role_name  = module.eks.node_iam_role_name
    cluster_name = module.eks.cluster_name
  })
  filename = "${path.module}/../auto-mode-config/nodepools/graviton-nodepool.yaml"
}

resource "local_file" "setup_gpu" {
  content = templatefile("${path.module}/../auto-mode-config/nodepool-templates/gpu-nodepool.yaml.tpl", {
    node_iam_role_name  = module.eks.node_iam_role_name
    cluster_name = module.eks.cluster_name
  })
  filename = "${path.module}/../auto-mode-config/nodepools/gpu-nodepool.yaml"
}