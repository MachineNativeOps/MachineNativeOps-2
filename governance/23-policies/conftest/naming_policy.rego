package naming

# 命名規範政策 - Namespace 與資源命名驗證（來源：governance/34-config/naming/canonical-naming-machine-spec.yaml）

canonical_regex := regex_from_spec {
  canonical_spec := data["canonical-naming-machine-spec"]
  regex_from_spec := canonical_spec.naming.canonical_regex
}
canonical_regex := "^(?!.*--)[a-z0-9-]+$" {
  not data["canonical-naming-machine-spec"]
}

env_prefixes[prefix] {
  canonical_spec := data["canonical-naming-machine-spec"]
  prefixes := canonical_spec.naming.environments
  prefix := prefixes[_]
}

# Namespace 命名規則（對齊 canonical-naming-machine-spec.yaml）
deny[msg] {
  input.kind == "Namespace"
  not regex.match(canonical_regex, input.metadata.name)
  msg := sprintf("Namespace 名稱 '%s' 不符合 canonical 格式：需以 team/tenant/dev/test/staging/prod/learn 開頭，僅允許小寫字母、數字與單一連字符，且不可連續 '-'。", [input.metadata.name])
}

# 若以環境 token 為前綴，需與 environment label 對齊
deny[msg] {
  input.kind == "Namespace"
  regex.match(canonical_regex, input.metadata.name)
  parts := split(input.metadata.name, "-")
  prefix := parts[0]
  env_prefixes[prefix]
  env := input.metadata.labels["environment"]
  env
  env != prefix
  msg := sprintf("Namespace 前綴 '%s' 必須與 environment 標籤 '%s' 對齊。", [prefix, env])
}

# Namespace 必須包含必要標籤（canonical required labels）
deny[msg] {
  input.kind == "Namespace"
  not input.metadata.labels["environment"]
  msg := "Namespace 缺少必要標籤：environment"
}

deny[msg] {
  input.kind == "Namespace"
  not input.metadata.labels["tenant"]
  msg := "Namespace 缺少必要標籤：tenant"
}

deny[msg] {
  input.kind == "Namespace"
  not input.metadata.labels["app.kubernetes.io/managed-by"]
  msg := "Namespace 缺少必要標籤：app.kubernetes.io/managed-by"
}

# Deployment 命名規則
deny[msg] {
  input.kind == "Deployment"
  not regex.match("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", input.metadata.name)
  msg := sprintf("Deployment 名稱 '%s' 不符合 Kubernetes 命名規範", [input.metadata.name])
}

# Service 必須有明確的 port 名稱
deny[msg] {
  input.kind == "Service"
  port := input.spec.ports[_]
  not port.name
  msg := sprintf("Service '%s' 的 port 必須有名稱定義", [input.metadata.name])
}

# 容器映像必須使用 SHA256 digest 而非 tag
warn[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not contains(container.image, "@sha256:")
  msg := sprintf("容器 '%s' 使用 tag 而非 SHA256 digest，建議使用固定 digest 提高安全性", [container.name])
}

# 資源名稱長度限制
deny[msg] {
  count(input.metadata.name) > 63
  msg := sprintf("資源名稱 '%s' 超過 63 字元限制", [input.metadata.name])
}
