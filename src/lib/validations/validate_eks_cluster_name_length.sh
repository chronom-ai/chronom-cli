validate_eks_cluster_name_length() {
  [[ ${#1} -le 14 ]] || echo "must be less than or equal to 14 characters"
}