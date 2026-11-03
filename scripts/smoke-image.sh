#!/usr/bin/env bash
set -euo pipefail
image="${1:?Expected immutable image reference}"
version="${2:?Expected application version}"
platform="${3:?Expected runtime platform}"
[[ "$image" == *@sha256:* || "$image" == sha256:* ]]
[[ "$platform" == linux/amd64 || "$platform" == linux/arm64 ]]
directory="$(mktemp -d /tmp/planner-image-smoke-XXXXXXXX)"
container=""
cleanup() {
  if [[ -n "$container" ]]; then docker rm -f "$container" >/dev/null; fi
  rm -rf "$directory"
}
trap cleanup EXIT
container="$(docker run -d --platform "$platform" --read-only --cap-drop ALL \
  --security-opt no-new-privileges:true \
  --label io.pockethive.planner.image-smoke=true \
  --tmpfs /tmp:rw,exec,nosuid,nodev,size=64m,mode=1777 \
  --tmpfs /data:rw,nosuid,nodev,size=32m,uid=10001,gid=10001,mode=0700 \
  -p 127.0.0.1::8765 "$image")"
port="$(docker inspect --format '{{(index (index .NetworkSettings.Ports "8765/tcp") 0).HostPort}}' "$container")"
[[ "$port" =~ ^[0-9]+$ ]]
origin="http://127.0.0.1:$port"
healthy=false
for attempt in {1..120}; do
  if curl --fail --silent --max-time 2 "$origin/health" >/dev/null; then healthy=true; break; fi
  if [[ "$(docker inspect --format '{{.State.Running}}' "$container")" != true ]]; then break; fi
  sleep 1
done
if [[ "$healthy" != true ]]; then docker logs "$container" >&2; exit 1; fi
curl --fail --silent --show-error --max-time 5 "$origin/api/info" > "$directory/info.json"
curl --fail --silent --show-error --max-time 5 "$origin/api/state" > "$directory/state.json"
python3 - "$directory" "$version" <<'PY'
import json
import pathlib
import sys

directory = pathlib.Path(sys.argv[1])
info = json.loads((directory / "info.json").read_text())
state = json.loads((directory / "state.json").read_text())
assert info["version"] == sys.argv[2], info
assert state == {"schemaVersion": 1, "revision": 0, "plans": []}, state
PY
printf 'PASS %s: version %s, healthy JRE/SQLite runtime, empty isolated workspace\n' "$platform" "$version"
