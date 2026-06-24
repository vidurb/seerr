#!/usr/bin/env sh
set -eu

CHART_DIR="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$CHART_DIR"

if command -v helm >/dev/null 2>&1 && helm plugin list 2>/dev/null | grep -q unittest; then
  helm unittest -f 'tests/settings_test.yaml' .
  exit 0
fi

echo "helm-unittest plugin not installed; running shell assertions"

render() {
  helm template test . "$@"
}

assert_not_contains() {
  haystack=$1
  needle=$2
  case $haystack in
    *"$needle"*) echo "expected output NOT to contain: $needle" >&2; exit 1 ;;
  esac
}

assert_contains() {
  haystack=$1
  needle=$2
  case $haystack in
    *"$needle"*) ;;
    *) echo "expected output to contain: $needle" >&2; exit 1 ;;
  esac
}

ui_output="$(render)"
assert_not_contains "$ui_output" "kind: Secret"
assert_not_contains "$ui_output" "apply-settings"

helm_output="$(render --set settings.management=helm --set settings.data.main.applicationTitle=CustomSeerr)"
assert_contains "$helm_output" "kind: Secret"
assert_contains "$helm_output" "CustomSeerr"
assert_contains "$helm_output" "apply-settings"

existing_output="$(render --set settings.management=helm --set settings.existingSecret=my-settings)"
assert_not_contains "$existing_output" "name: test-seerr-chart-settings"
assert_contains "$existing_output" "secretName: my-settings"

echo "settings chart tests passed"
