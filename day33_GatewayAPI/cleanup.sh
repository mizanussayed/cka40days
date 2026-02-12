#!/bin/bash
# Cleanup NGINX Gateway Fabric and Kind Cluster
# This script removes all resources created during deployment

echo "=== NGINX Gateway Fabric Cleanup Script ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

read -p "Are you sure you want to cleanup? This will delete all resources. (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup process..."
echo ""

# Step 1: Delete HTTPRoute
echo "[1/5] Deleting HTTPRoute..."
kubectl delete httproute frontend-route --namespace default 2>/dev/null || echo "  → HTTPRoute not found"
echo "✓ HTTPRoute deleted"
echo ""

# Step 2: Delete sample application
echo "[2/5] Deleting sample application..."
kubectl delete pod frontend-app --namespace default 2>/dev/null || echo "  → Pod not found"
kubectl delete svc frontend-svc --namespace default 2>/dev/null || echo "  → Service not found"
echo "✓ Sample application deleted"
echo ""

# Step 3: Delete Gateway resources
echo "[3/5] Deleting Gateway resources..."
kubectl delete gateway nginx-gateway -n nginx-gateway 2>/dev/null || echo "  → Gateway not found"
echo "✓ Gateway resources deleted"
echo ""

# Step 4: Delete NGINX Gateway Fabric
echo "[4/5] Deleting NGINX Gateway Fabric..."
helm uninstall ngf -n nginx-gateway 2>/dev/null || echo "  → Helm release not found"
kubectl delete namespace nginx-gateway 2>/dev/null || echo "  → Namespace not found"
echo "✓ NGINX Gateway Fabric deleted"
echo ""

# Step 5: Delete Gateway API CRDs
echo "[5/5] Deleting Gateway API CRDs..."
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml 2>/dev/null || echo "  → Gateway API CRDs already deleted or not found"
echo "✓ Gateway API CRDs deleted"
echo ""

# Step 6: Delete Kind cluster (optional)
echo ""
echo "Checking for Kind cluster..."
if kind get clusters 2>/dev/null | grep -q "gateway-demo"; then
    read -p "Do you want to delete the Kind cluster 'gateway-demo'? (yes/no): " delete_cluster
    if [ "$delete_cluster" = "yes" ]; then
        echo "Deleting Kind cluster..."
        kind delete cluster --name gateway-demo
        echo "✓ Kind cluster deleted"
    else
        echo "Keeping Kind cluster"
    fi
else
    echo "Kind cluster 'gateway-demo' not found"
fi

echo ""
echo -e "${GREEN}=== Cleanup Complete ===${NC}"
echo ""
echo "Verification:"
echo "  Remaining pods: $(kubectl get pods --all-namespaces 2>/dev/null | wc -l)"
echo "  Remaining gateways: $(kubectl get gateway --all-namespaces 2>/dev/null | wc -l)"
echo "  Remaining httproutes: $(kubectl get httproute --all-namespaces 2>/dev/null | wc -l)"
echo ""
