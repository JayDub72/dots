# lib/log.sh — shared logging, sourced by bin/dots and every module.
#
# Every subcommand run writes to both the screen (colored, if interactive)
# and a timestamped log file. Defaults to logs/ inside this repo (kept out
# of git — see .gitignore) so nothing writes outside dots unless you
# explicitly point it elsewhere: override with DOTS_LOG_DIR, e.g.
#   DOTS_LOG_DIR="$HOME/Documents/Logs/dots" ./bin/dots all

if [[ -t 1 ]]; then
    readonly C_RESET=$'\033[0m'
    readonly C_BOLD=$'\033[1m'
    readonly C_RED=$'\033[31m'
    readonly C_GREEN=$'\033[32m'
    readonly C_YELLOW=$'\033[33m'
    readonly C_BLUE=$'\033[34m'
    readonly C_CYAN=$'\033[36m'
else
    readonly C_RESET="" C_BOLD="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_CYAN=""
fi

readonly LOG_DIR="${DOTS_LOG_DIR:-${DOTS_ROOT}/logs}"
readonly LOG_FILE="${LOG_DIR}/${DOTS_COMMAND:-dots}-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"
: > "$LOG_FILE"

_ts() { date '+%Y-%m-%d %H:%M:%S'; }

log_info()    { printf '%s %s[INFO]%s  %s\n'    "$(_ts)" "${C_BLUE}"   "${C_RESET}" "$*" | tee -a "$LOG_FILE"; }
log_success() { printf '%s %s[ OK ]%s  %s\n'    "$(_ts)" "${C_GREEN}"  "${C_RESET}" "$*" | tee -a "$LOG_FILE"; }
log_warn()    { printf '%s %s[WARN]%s  %s\n'    "$(_ts)" "${C_YELLOW}" "${C_RESET}" "$*" | tee -a "$LOG_FILE"; }
log_error()   { printf '%s %s[FAIL]%s  %s\n'    "$(_ts)" "${C_RED}"    "${C_RESET}" "$*" | tee -a "$LOG_FILE" >&2; }
log_step()    { printf '\n%s %s==>%s %s%s%s\n' "$(_ts)" "${C_CYAN}${C_BOLD}" "${C_RESET}" "${C_BOLD}" "$*" "${C_RESET}" | tee -a "$LOG_FILE"; }

die() {
    log_error "$*"
    exit 1
}

# Run a named step. The step function must be idempotent and return
# non-zero on failure. Failures are logged and recorded but do NOT abort
# the rest of a multi-step command (e.g. `dots all`), so later
# independent steps still get a chance to run.
#
# A step may also return 2 to mean "intentionally skipped" (e.g. no
# Brewfile yet) — recorded distinctly from a real failure.
declare -a STEP_NAMES=()
declare -a STEP_RESULTS=()

run_step() {
    local step_name="$1"
    local step_fn="$2"
    log_step "$step_name"
    local start_ts elapsed rc
    start_ts="$(date +%s)"
    "$step_fn"
    rc=$?
    elapsed=$(( $(date +%s) - start_ts ))
    STEP_NAMES+=("$step_name")
    case "$rc" in
        0)
            log_success "$step_name completed in ${elapsed}s"
            STEP_RESULTS+=("OK")
            ;;
        2)
            log_warn "$step_name skipped after ${elapsed}s"
            STEP_RESULTS+=("SKIPPED")
            ;;
        *)
            log_error "$step_name failed after ${elapsed}s (see log: $LOG_FILE)"
            STEP_RESULTS+=("FAILED")
            ;;
    esac
}

print_summary() {
    [[ ${#STEP_NAMES[@]} -eq 0 ]] && return 0
    log_step "Summary"
    local i failures=0
    for i in "${!STEP_NAMES[@]}"; do
        case "${STEP_RESULTS[$i]}" in
            OK)      printf '  %s✔%s %s\n' "${C_GREEN}" "${C_RESET}" "${STEP_NAMES[$i]}" | tee -a "$LOG_FILE" ;;
            SKIPPED) printf '  %s—%s %s %s(skipped)%s\n' "${C_YELLOW}" "${C_RESET}" "${STEP_NAMES[$i]}" "${C_YELLOW}" "${C_RESET}" | tee -a "$LOG_FILE" ;;
            *)       printf '  %s✘%s %s\n' "${C_RED}" "${C_RESET}" "${STEP_NAMES[$i]}" | tee -a "$LOG_FILE"; failures=$((failures + 1)) ;;
        esac
    done
    echo | tee -a "$LOG_FILE"
    log_info "Full log: ${LOG_FILE}"
    [[ "$failures" -eq 0 ]]
}
