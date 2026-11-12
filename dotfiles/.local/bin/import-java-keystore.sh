#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

error() {
  printf 'ERROR: %s\n' "$*" >&2
}

find_keystore() {
  local candidate

  for candidate in \
    "$JAVA_HOME/lib/security/cacerts" \
    "$JAVA_HOME/jre/lib/security/cacerts"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

certificate_files() {
  local file
  shopt -s nullglob
  for file in "$SCRIPT_DIR"/*.crt "$SCRIPT_DIR"/*.cer "$SCRIPT_DIR"/*.pem \
    "$SCRIPT_DIR"/*.der; do
    [[ -f "$file" ]] && printf '%s\n' "$file"
  done
}

certificate_alias() {
  local filename=${1##*/}
  printf '%s\n' "${filename%.*}"
}

import_certificates() {
  local keystore=$1
  shift
  local certificate alias
  local imported=0 skipped=0 failed=0

  for certificate in "$@"; do
    alias=$(certificate_alias "$certificate")

    if keytool -list -keystore "$keystore" -alias "$alias" \
      -storepass changeit >/dev/null 2>&1; then
      log "Skipped '$certificate' (alias '$alias' is already present)"
      ((skipped += 1))
      continue
    fi

    if keytool -importcert -noprompt -trustcacerts -alias "$alias" \
      -file "$certificate" -keystore "$keystore" -storepass changeit \
      >/dev/null 2>&1; then
      log "Imported '$certificate' as alias '$alias'"
      ((imported += 1))
    else
      error "Failed to import '$certificate' as alias '$alias'"
      ((failed += 1))
    fi
  done

  log "Finished: $imported imported, $skipped skipped, $failed failed"
  (( failed == 0 ))
}

main() {
  local keystore
  local -a certificates

  if [[ -z "${JAVA_HOME:-}" ]]; then
    error 'JAVA_HOME is not set; no certificates were imported'
    return 1
  fi

  if ! command -v keytool >/dev/null 2>&1; then
    error 'keytool was not found in PATH; no certificates were imported'
    return 1
  fi

  if ! keystore=$(find_keystore); then
    error "No cacerts keystore found under JAVA_HOME '$JAVA_HOME'; no certificates were imported"
    return 1
  fi

  mapfile -t certificates < <(certificate_files)
  if (( ${#certificates[@]} == 0 )); then
    error "No certificates found in '$SCRIPT_DIR'; nothing to import"
    return 1
  fi

  log "Using Java keystore '$keystore'"
  import_certificates "$keystore" "${certificates[@]}"
}

main "$@"
