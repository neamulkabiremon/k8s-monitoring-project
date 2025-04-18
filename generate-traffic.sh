#!/bin/bash

PODINFO_URL="${1:-http://127.0.0.1:8080}"

echo ""
echo "🌐 Target Podinfo URL: $PODINFO_URL"
echo "🚀 Simulating realistic traffic with metrics, logs, and traces"
echo "⏱ Press Ctrl+C to stop."
echo ""

# Use temporary files to share counter state between functions
SUCCESS_FILE=$(mktemp)
FAIL_FILE=$(mktemp)
TOTAL_FILE=$(mktemp)
echo 0 > "$SUCCESS_FILE"
echo 0 > "$FAIL_FILE"
echo 0 > "$TOTAL_FILE"

# Clean up temp files on exit
cleanup() {
  rm -f "$SUCCESS_FILE" "$FAIL_FILE" "$TOTAL_FILE"
  echo "👋 Load simulation stopped."
}
trap cleanup EXIT

# Update stats
update_stats() {
  local code="$1"
  echo $(( $(<"$TOTAL_FILE") + 1 )) > "$TOTAL_FILE"
  if [[ "$code" =~ ^2 ]]; then
    echo $(( $(<"$SUCCESS_FILE") + 1 )) > "$SUCCESS_FILE"
  else
    echo $(( $(<"$FAIL_FILE") + 1 )) > "$FAIL_FILE"
  fi
}

# Send requests loop
send_requests() {
  while true; do
    endpoints=(
      "/" "/version" "/healthz" "/readyz" "/headers" "/env" "/configs"
      "/status/200" "/status/404" "/status/500"
      "/delay/1" "/chunked/1"
    )

    for endpoint in "${endpoints[@]}"; do
      code=$(curl -s -o /dev/null -w "%{http_code}" "$PODINFO_URL$endpoint")
      update_stats "$code"
    done

    # Echo
    code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$PODINFO_URL/echo" \
      -H "Content-Type: application/json" \
      -d '{"message":"Hello from macOS script"}')
    update_stats "$code"

    # JWT + validate
    JWT=$(curl -s -X POST -d 'anon' "$PODINFO_URL/token" | jq -r .token)
    if [[ $JWT != "null" && -n "$JWT" ]]; then
      code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $JWT" "$PODINFO_URL/token/validate")
      update_stats "$code"
    fi

    # Cache simulation
    curl -s -X POST "$PODINFO_URL/cache/test" -d 'val' > /dev/null
    curl -s "$PODINFO_URL/cache/test" > /dev/null
    curl -s -X DELETE "$PODINFO_URL/cache/test" > /dev/null

    # File write
    curl -s -X POST "$PODINFO_URL/store" -d 'log this file' > /dev/null

    sleep 1
  done
}

# Stats printer
print_stats() {
  while true; do
    sleep 5
    success=$(<"$SUCCESS_FILE")
    fail=$(<"$FAIL_FILE")
    total=$(<"$TOTAL_FILE")

    echo ""
    echo "📊 Stats for last 5 seconds:"
    echo "  ✅ Success: $success"
    echo "  ❌ Failures: $fail"
    echo "  📦 Total Requests: $total"
    echo ""

    echo 0 > "$SUCCESS_FILE"
    echo 0 > "$FAIL_FILE"
    echo 0 > "$TOTAL_FILE"
  done
}

# Start stats printer in background
print_stats &

# Run traffic generator
send_requests