#!/usr/bin/env bash
#-----------------------------------------------------------------------------------------
# End-to-end test of helm-watchdog-pod-delete.
#
# Preconditions: the chart is already deployed in the cluster (make deploy or
# make deploy-argocd). Normally executed by "make e2e" or "make e2e-argocd".
#
# Checks:
#   1. The watchdog Deployment is ready and runs as non-root.
#   2. A bare pod with status "Error" is deleted by the watchdog.
#   3. A pod in "CrashLoopBackOff" (managed by a Deployment) is deleted by the watchdog.
#   4. The watchdog never deletes pods in its own namespace and never restarts.
#
# Environment variables:
#   KUBE_CONTEXT    kubectl context (required, e.g. kind-watchdog)
#   NAMESPACE       namespace of the watchdog (default: helm-watchdog-pod-delete)
#   DEPLOYMENT      name of the watchdog Deployment (default: helm-watchdog-pod-delete)
#   CRASH_MANIFEST  manifest with the failing pods (default: examples/test-crash-pods.yaml)
#   TIMEOUT         seconds to wait for each check (default: 240)
#-----------------------------------------------------------------------------------------
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${KUBE_CONTEXT:?KUBE_CONTEXT must be set (e.g. kind-watchdog)}"
NAMESPACE="${NAMESPACE:-helm-watchdog-pod-delete}"
DEPLOYMENT="${DEPLOYMENT:-helm-watchdog-pod-delete}"
CRASH_MANIFEST="${CRASH_MANIFEST:-${SCRIPT_DIR}/../examples/test-crash-pods.yaml}"
TIMEOUT="${TIMEOUT:-240}"
CRASH_NAMESPACE="test-crash"

kube() {
  kubectl --context "${KUBE_CONTEXT}" "$@"
}

log() {
  printf '%s %s\n' "$(date -u +%H:%M:%S)" "$*"
}

fail() {
  log "[FAIL] $*"
  log "[DEBUG] Watchdog logs:"
  kube -n "${NAMESPACE}" logs "deploy/${DEPLOYMENT}" --tail=50 || true
  log "[DEBUG] Pods in ${CRASH_NAMESPACE}:"
  kube -n "${CRASH_NAMESPACE}" get pods -o wide || true
  exit 1
}

cleanup() {
  log "[INFO] Removing test workloads..."
  kube delete -f "${CRASH_MANIFEST}" --ignore-not-found --wait=false >/dev/null 2>&1 || true
}
trap cleanup EXIT

# Waits until the command passed as argument succeeds or TIMEOUT expires
wait_for() {
  local description="$1"
  shift
  local deadline=$((SECONDS + TIMEOUT))
  log "[INFO] Waiting: ${description}"
  until "$@"; do
    if ((SECONDS >= deadline)); then
      fail "Timeout (${TIMEOUT}s) waiting: ${description}"
    fi
    sleep 5
  done
  log "[OK] ${description}"
}

watchdog_logs_contain() {
  kube -n "${NAMESPACE}" logs "deploy/${DEPLOYMENT}" 2>/dev/null | grep -q -- "$1"
}

#-----------------------------------------------------------------------------------------
log "[INFO] Context: ${KUBE_CONTEXT} | Namespace: ${NAMESPACE} | Deployment: ${DEPLOYMENT}"

# 1. Watchdog is ready and hardened
kube -n "${NAMESPACE}" rollout status "deploy/${DEPLOYMENT}" --timeout="${TIMEOUT}s" \
  || fail "Deployment ${DEPLOYMENT} is not ready"
run_as_non_root="$(kube -n "${NAMESPACE}" get "deploy/${DEPLOYMENT}" \
  -o jsonpath='{.spec.template.spec.securityContext.runAsNonRoot}')"
[[ "${run_as_non_root}" == "true" ]] || fail "Watchdog must run as non-root"
log "[OK] Watchdog is ready and runs as non-root"

restarts_before="$(kube -n "${NAMESPACE}" get pods -l "app.kubernetes.io/name=helm-watchdog-pod-delete" \
  -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | awk '{s+=$1} END {print s+0}')"

wait_for "watchdog started" watchdog_logs_contain "Monitoring pods with errors"

# 2 and 3. Pods with errors are deleted
log "[INFO] Creating pods that fail on purpose..."
kube apply -f "${CRASH_MANIFEST}"

wait_for "pod test-crash-error deleted by the watchdog" \
  watchdog_logs_contain "Deleting pod: test-crash-error in namespace: ${CRASH_NAMESPACE}"

error_pod_absent() {
  ! kube -n "${CRASH_NAMESPACE}" get pod test-crash-error >/dev/null 2>&1
}
wait_for "pod test-crash-error no longer exists" error_pod_absent

wait_for "failing pod of Deployment test-crash-loop deleted by the watchdog" \
  watchdog_logs_contain "Deleting pod: test-crash-loop-"

# 4. The watchdog does not delete itself and does not restart
if watchdog_logs_contain "in namespace: ${NAMESPACE} "; then
  fail "Watchdog deleted pods in its own namespace (${NAMESPACE})"
fi
restarts_after="$(kube -n "${NAMESPACE}" get pods -l "app.kubernetes.io/name=helm-watchdog-pod-delete" \
  -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | awk '{s+=$1} END {print s+0}')"
[[ "${restarts_after}" == "${restarts_before}" ]] \
  || fail "Watchdog container restarted (${restarts_before} -> ${restarts_after})"
log "[OK] Watchdog ignored its own namespace and did not restart"

log "[OK] End-to-end test passed"
