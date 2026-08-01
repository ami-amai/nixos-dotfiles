#!/usr/bin/env bash
set -euo pipefail

DEFAULT_INTERVAL=5
USER_ID="${SUDO_UID:-$(id -u)}"
SCRIPT_PATH="${BASH_SOURCE[0]}"
RUNTIME_DIR="/run/ryzenadj-mode-${USER_ID}"
STATE_FILE="${RUNTIME_DIR}/state"
PROFILE_FILE="${RUNTIME_DIR}/profile"
LOCK_FILE="${RUNTIME_DIR}/ryzenadj.lock"
UNIT_NAME="ryzenadj-mode-${USER_ID}.service"
SYSTEM_PATH="/run/wrappers/bin:/run/current-system/sw/bin"

BASE_STAPM_LIMIT=20000
BASE_FAST_LIMIT=30000
BASE_SLOW_LIMIT=25000
BASE_APU_SLOW_LIMIT=15000
BASE_TCTL_TEMP=85
BASE_VRM_CURRENT=33000
BASE_VRMSOC_CURRENT=13000
BASE_VRMMAX_CURRENT=50000
BASE_VRMSOCMAX_CURRENT=17000

declare -A BASE_VALUES=(
  [stapm-limit]=$BASE_STAPM_LIMIT
  [fast-limit]=$BASE_FAST_LIMIT
  [slow-limit]=$BASE_SLOW_LIMIT
  [apu-slow-limit]=$BASE_APU_SLOW_LIMIT
  [tctl-temp]=$BASE_TCTL_TEMP
  [vrm-current]=$BASE_VRM_CURRENT
  [vrmsoc-current]=$BASE_VRMSOC_CURRENT
  [vrmmax-current]=$BASE_VRMMAX_CURRENT
  [vrmsocmax-current]=$BASE_VRMSOCMAX_CURRENT
)

# Options accepted directly by manual and relative modes. Options not listed
# here remain available after the explicit `--` separator for compatibility.
RYZEN_VALUE_OPTIONS=(
  stapm-limit fast-limit slow-limit slow-time stapm-time tctl-temp
  vrm-current vrmsoc-current vrmgfx-current vrmcvip-current
  vrmmax-current vrmsocmax-current vrmgfxmax_current
  psi0-current psi3cpu_current psi0soc-current psi3gfx_current
  max-socclk-frequency min-socclk-frequency
  max-fclk-frequency min-fclk-frequency
  max-vcn min-vcn max-lclk min-lclk max-gfxclk min-gfxclk
  prochot-deassertion-ramp apu-skin-temp dgpu-skin-temp
  apu-slow-limit skin-temp-limit gfx-clk oc-clk oc-volt
  set-coall set-coper set-cogfx
)
RYZEN_FLAG_OPTIONS=(enable-oc disable-oc power-saving max-performance)

STATUS_PARAMETERS=(
  stapm-limit fast-limit slow-limit slow-time stapm-time
  apu-slow-limit skin-temp-limit
  tctl-temp apu-skin-temp dgpu-skin-temp
  vrm-current vrmsoc-current vrmgfx-current vrmcvip-current
  vrmmax-current vrmsocmax-current vrmgfxmax_current
  psi0-current psi3cpu_current psi0soc-current psi3gfx_current
  max-socclk-frequency min-socclk-frequency
  max-fclk-frequency min-fclk-frequency
  max-vcn min-vcn max-lclk min-lclk max-gfxclk min-gfxclk
  gfx-clk oc-clk oc-volt set-coall set-coper set-cogfx
  prochot-deassertion-ramp enable-oc disable-oc
  power-saving max-performance
)

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    exec sudo -- "$SCRIPT_PATH" "$@"
  fi
}

usage() {
  cat <<'EOF'
Usage:
  ryzenadj-mode --status
  ryzenadj-mode --help
  ryzenadj-mode stop
  ryzenadj-mode restore
  ryzenadj-mode defaults
  ryzenadj-mode manual [options] <ryzenadj options>
  ryzenadj-mode relative [options] [parameter value] [ryzenadj options]

Modes:
  manual
    Applies the explicitly supplied ryzenadj settings. Group percentages scale
    matching supplied settings; omitted ryzenadj settings are not invented.

  relative
    With PARAMETER VALUE, derives one ratio from the configured base values and
    scales the known power/current defaults. Without them, starts from 100% of
    the base values. Explicit ryzenadj settings override generated settings.

Group percentages (manual and relative):
  --limit PERCENT         Scale every supplied/generated *-limit setting.
                          Default: 100.
  --temp PERCENT          Scale every supplied/generated *-temp setting.
                          Default: 100.
  --current PERCENT       Scale every supplied/generated *-current and
                          *_current setting. Default: 100.

  Percentages are applied last, including to explicit overrides. Values above
  100 are accepted. Zero and negative percentages are rejected.

Process and enforcement options:
  --interval SECONDS       Enforcement period (minimum 0.1). Default: 5.
  --boost on|off           Force CPU boost state.
  --min-freq KHZ           Set CPU scaling_min_freq on all policies.
  --max-freq KHZ           Set CPU scaling_max_freq on all policies.
  --freq KHZ               Set min and max CPU frequency.
  --cores N                Keep only N logical CPUs online when possible.
  --once                   Apply once and do not start background enforcer.
  -h, --help               Show this help and exit.

Power, temperature, and current settings:
  --stapm-limit VALUE      Sustained package power limit, mW.
  --fast-limit VALUE       Fast/instantaneous package power limit, mW.
  --slow-limit VALUE       Average package power limit, mW.
  --apu-slow-limit VALUE   APU slow PPT limit, mW.
  --skin-temp-limit VALUE  Skin-temperature power limit, mW.
  --tctl-temp VALUE        Core/APU thermal limit, degrees C.
  --apu-skin-temp VALUE    APU skin-temperature limit, degrees C.
  --dgpu-skin-temp VALUE   Discrete-GPU skin-temperature limit, degrees C.
  --vrm-current VALUE      Sustained CPU/VDD current limit, mA.
  --vrmsoc-current VALUE   Sustained SoC current limit, mA.
  --vrmgfx-current VALUE   Sustained iGPU current limit, mA.
  --vrmcvip-current VALUE  Sustained CVIP current limit, mA.
  --vrmmax-current VALUE   Peak CPU/VDD current limit, mA.
  --vrmsocmax-current V    Peak SoC current limit, mA.
  --vrmgfxmax_current V    Peak iGPU current limit, mA.
  --psi0-current VALUE     PSI0 CPU/VDD current threshold, mA.
  --psi3cpu_current VALUE  PSI3 CPU current threshold, mA.
  --psi0soc-current VALUE  PSI0 SoC current threshold, mA.
  --psi3gfx_current VALUE  PSI3 iGPU current threshold, mA.

Clock and timing settings:
  --stapm-time SEC         STAPM averaging time constant.
  --slow-time SEC          Slow PPT averaging time constant.
  --min-socclk-frequency MHz / --max-socclk-frequency MHz
                          SoC clock range.
  --min-fclk-frequency MHz / --max-fclk-frequency MHz
                          fabric/data-fabric clock range.
  --min-vcn MHz / --max-vcn MHz
                          video encode/decode engine clock range.
  --min-lclk MHz / --max-lclk MHz
                          data-launch clock range.
  --min-gfxclk MHz / --max-gfxclk MHz
                          iGPU clock range.
  --gfx-clk MHz            Force Renoir iGPU clock.

Overclocking and curve optimizer (use with care):
  --enable-oc              Enable SMU overclocking controls.
  --disable-oc             Disable SMU overclocking controls.
  --oc-clk MHz             Force CPU core clock.
  --oc-volt VID            Force CPU VID in ryzenadj encoding.
  --set-coall VALUE        All-core curve optimizer value.
  --set-coper VALUE        Per-core curve optimizer value.
  --set-cogfx VALUE        iGPU curve optimizer value.

Other ryzenadj settings:
  --prochot-deassertion-ramp VALUE
                          Power ramp after PROCHOT deassertion.
  --power-saving           Apply firmware-specific hidden saving settings.
  --max-performance        Apply firmware-specific hidden performance settings.

Relative reference parameters:
  stapm-limit fast-limit slow-limit apu-slow-limit tctl-temp
  vrm-current vrmsoc-current vrmmax-current vrmsocmax-current

Examples:
  ryzenadj-mode relative --limit 70 --temp 80 --current 75
  ryzenadj-mode relative fast-limit 20 --temp 90 --tctl-temp 70
  ryzenadj-mode relative fast-limit 20 --max-gfxclk 1200 --gfx-clk 1000
  ryzenadj-mode manual --limit 80 --stapm-limit 15 --fast-limit 20
  ryzenadj-mode manual --max-gfxclk 1200 --vrmgfx-current 10 --interval 2
  ryzenadj-mode manual --enable-oc --oc-clk 1800 --oc-volt 48

Status suitable for watch:
  sudo watch -n 1 /home/ami/.config/zsh/scripts/ryzenadj-mode.sh --status

Notes:
  Power/current values below 1000 are treated as W/A-style short values and
  converted to mW/mA. Clock and temperature values are not multiplied.
  ryzenadj cannot read back every clock/OC register. --status shows the active
  target and reports actual=n/a for write-only values.
  stop/restore restores readable power, current, temperature, CPU frequency,
  boost, governor, and online-core state. Write-only clock/OC settings may need
  --disable-oc or a reboot to return fully to firmware defaults.
  Logs for the background enforcer are available with:
    journalctl -u ryzenadj-mode-$(id -u).service
EOF
}

init_runtime_dir() {
  [[ "$EUID" -eq 0 ]] || return 0
  if [[ -L "$RUNTIME_DIR" ]]; then
    printf 'Refusing symlink runtime directory: %s\n' "$RUNTIME_DIR" >&2
    exit 1
  fi
  install -d -o root -g root -m 0700 "$RUNTIME_DIR"
  [[ "$(stat -c '%u:%a' "$RUNTIME_DIR")" == "0:700" ]] || {
    printf 'Unsafe runtime directory: %s\n' "$RUNTIME_DIR" >&2
    exit 1
  }
  # Remove files used by versions that stored root-controlled data in /tmp.
  rm -f "/tmp/ryzenadj-mode-${USER_ID}.env" "/tmp/ryzenadj-mode-${USER_ID}.pid" "/tmp/ryzenadj-mode-${USER_ID}.log"
}

ryzen_info() {
  flock -x "$LOCK_FILE" ryzenadj -i 2>/dev/null
}

ryzenadj_locked() {
  flock -x "$LOCK_FILE" ryzenadj "$@"
}

table_value() {
  local key="$1"
  awk -F'|' -v key="$key" '
    $2 ~ key {
      gsub(/^[ \t]+|[ \t]+$/, "", $3)
      print $3
      exit
    }
  '
}

save_state() {
  [[ -e "$STATE_FILE" ]] && return

  local info policy cpu tmp
  info="$(ryzen_info)" || { printf 'Unable to read current ryzenadj state\n' >&2; return 1; }
  [[ -n "$info" ]] || { printf 'ryzenadj returned an empty state\n' >&2; return 1; }
  tmp="$(mktemp "${RUNTIME_DIR}/state.XXXXXX")"
  chmod 0600 "$tmp"
  {
    printf 'STAPM_LIMIT=%s\n' "$(printf '%s\n' "$info" | table_value 'STAPM LIMIT')"
    printf 'FAST_LIMIT=%s\n' "$(printf '%s\n' "$info" | table_value 'PPT LIMIT FAST')"
    printf 'SLOW_LIMIT=%s\n' "$(printf '%s\n' "$info" | table_value 'PPT LIMIT SLOW')"
    printf 'SLOW_TIME=%s\n' "$(printf '%s\n' "$info" | table_value 'SlowPPTTimeConst')"
    printf 'STAPM_TIME=%s\n' "$(printf '%s\n' "$info" | table_value 'StapmTimeConst')"
    printf 'APU_SLOW_LIMIT=%s\n' "$(printf '%s\n' "$info" | table_value 'PPT LIMIT APU')"
    printf 'TCTL_TEMP=%s\n' "$(printf '%s\n' "$info" | table_value 'THM LIMIT CORE')"
    printf 'APU_SKIN_TEMP=%s\n' "$(printf '%s\n' "$info" | table_value 'STT LIMIT APU')"
    printf 'DGPU_SKIN_TEMP=%s\n' "$(printf '%s\n' "$info" | table_value 'STT LIMIT dGPU')"
    printf 'VRM_CURRENT=%s\n' "$(printf '%s\n' "$info" | table_value 'TDC LIMIT VDD')"
    printf 'VRMSOC_CURRENT=%s\n' "$(printf '%s\n' "$info" | table_value 'TDC LIMIT SOC')"
    printf 'VRMMAX_CURRENT=%s\n' "$(printf '%s\n' "$info" | table_value 'EDC LIMIT VDD')"
    printf 'VRMSOCMAX_CURRENT=%s\n' "$(printf '%s\n' "$info" | table_value 'EDC LIMIT SOC')"
    [[ -r /sys/devices/system/cpu/cpufreq/boost ]] && printf 'BOOST=%s\n' "$(< /sys/devices/system/cpu/cpufreq/boost)"
    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
      [[ -d "$policy" ]] || continue
      [[ -r "$policy/scaling_governor" ]] && printf 'GOV_%s=%s\n' "${policy##*policy}" "$(<"$policy/scaling_governor")"
      [[ -r "$policy/scaling_min_freq" ]] && printf 'MIN_%s=%s\n' "${policy##*policy}" "$(<"$policy/scaling_min_freq")"
      [[ -r "$policy/scaling_max_freq" ]] && printf 'MAX_%s=%s\n' "${policy##*policy}" "$(<"$policy/scaling_max_freq")"
    done
    for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
      [[ -r "$cpu/online" ]] || continue
      printf 'CPU_%s=%s\n' "${cpu##*cpu}" "$(<"$cpu/online")"
    done
  } >"$tmp"
  mv -f "$tmp" "$STATE_FILE"
  return 0
}

to_ryzen_unit() {
  local parameter="$1" value="$2"
  if [[ ! "$value" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf 'Invalid value for %s: %s\n' "$parameter" "$value" >&2
    exit 2
  fi

  case "$parameter" in
    tctl-temp|apu-skin-temp|dgpu-skin-temp|slow-time|stapm-time|*-frequency|max-vcn|min-vcn|max-lclk|min-lclk|max-gfxclk|min-gfxclk|gfx-clk|oc-clk|oc-volt|set-coall|set-coper|set-cogfx|prochot-deassertion-ramp)
      awk -v v="$value" 'BEGIN { printf "%.0f\n", v }'
      ;;
    *)
      awk -v v="$value" 'BEGIN { if (v < 1000) v *= 1000; printf "%.0f\n", v }'
      ;;
  esac
}

set_boost() {
  local value="$1"
  case "$value" in
    on|1|true) value=1 ;;
    off|0|false) value=0 ;;
    *) printf 'Invalid --boost value: %s\n' "$value" >&2; exit 2 ;;
  esac
  [[ -w /sys/devices/system/cpu/cpufreq/boost ]] && printf '%s\n' "$value" >/sys/devices/system/cpu/cpufreq/boost
}

set_governor() {
  local gov="$1" policy
  for policy in /sys/devices/system/cpu/cpufreq/policy*; do
    policy_is_online "$policy" || continue
    [[ -w "$policy/scaling_governor" ]] && printf '%s\n' "$gov" >"$policy/scaling_governor" || true
  done
}

policy_is_online() {
  local policy="$1" cpu
  [[ -r "$policy/affected_cpus" ]] || return 1
  cpu="$(cat "$policy/affected_cpus" 2>/dev/null || true)"
  [[ -n "$cpu" ]]
}

set_freqs() {
  local min_freq="$1" max_freq="$2" policy hw_min hw_max current_min current_max
  [[ -z "$min_freq" || "$min_freq" =~ ^[0-9]+$ ]] || { printf 'Invalid --min-freq: %s\n' "$min_freq" >&2; exit 2; }
  [[ -z "$max_freq" || "$max_freq" =~ ^[0-9]+$ ]] || { printf 'Invalid --max-freq: %s\n' "$max_freq" >&2; exit 2; }
  [[ -z "$min_freq" || -z "$max_freq" || "$min_freq" -le "$max_freq" ]] || {
    printf -- '--min-freq must not exceed --max-freq\n' >&2
    exit 2
  }
  for policy in /sys/devices/system/cpu/cpufreq/policy*; do
    [[ -d "$policy" ]] || continue
    policy_is_online "$policy" || continue
    hw_min="$(<"$policy/cpuinfo_min_freq")"
    hw_max="$(<"$policy/cpuinfo_max_freq")"
    [[ -z "$min_freq" || ( "$min_freq" -ge "$hw_min" && "$min_freq" -le "$hw_max" ) ]] || {
      printf 'Minimum frequency %s is outside %s..%s for %s\n' "$min_freq" "$hw_min" "$hw_max" "$policy" >&2; exit 2;
    }
    [[ -z "$max_freq" || ( "$max_freq" -ge "$hw_min" && "$max_freq" -le "$hw_max" ) ]] || {
      printf 'Maximum frequency %s is outside %s..%s for %s\n' "$max_freq" "$hw_min" "$hw_max" "$policy" >&2; exit 2;
    }
    current_min="$(<"$policy/scaling_min_freq")"
    current_max="$(<"$policy/scaling_max_freq")"
    [[ -z "$max_freq" || "$max_freq" -ge "$current_min" || -n "$min_freq" ]] || {
      printf 'Cannot lower maximum below current minimum %s without --min-freq for %s\n' "$current_min" "$policy" >&2; exit 2;
    }
    [[ -z "$min_freq" || "$min_freq" -le "$current_max" || -n "$max_freq" ]] || {
      printf 'Cannot raise minimum above current maximum %s without --max-freq for %s\n' "$current_max" "$policy" >&2; exit 2;
    }
    # Lower the minimum first when necessary; otherwise raise the maximum first.
    if [[ -n "$max_freq" && "$max_freq" -lt "$current_min" ]]; then
      [[ -n "$min_freq" && -w "$policy/scaling_min_freq" ]] && printf '%s\n' "$min_freq" >"$policy/scaling_min_freq"
      [[ -w "$policy/scaling_max_freq" ]] && printf '%s\n' "$max_freq" >"$policy/scaling_max_freq"
    else
      [[ -n "$max_freq" && -w "$policy/scaling_max_freq" ]] && printf '%s\n' "$max_freq" >"$policy/scaling_max_freq"
      [[ -n "$min_freq" && -w "$policy/scaling_min_freq" ]] && printf '%s\n' "$min_freq" >"$policy/scaling_min_freq"
    fi
  done
}

set_cores() {
  local keep="$1" cpu idx total
  [[ "$keep" =~ ^[0-9]+$ && "$keep" -ge 1 ]] || { printf 'Invalid --cores value: %s\n' "$keep" >&2; exit 2; }
  total="$(nproc --all)"
  (( keep <= total )) || { printf -- '--cores %s exceeds available logical CPUs (%s)\n' "$keep" "$total" >&2; exit 2; }
  for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    idx="${cpu##*cpu}"
    [[ "$idx" == "0" || -w "$cpu/online" ]] || continue
    if (( idx < keep )); then
      [[ -w "$cpu/online" ]] && printf '1\n' >"$cpu/online" || true
    else
      [[ -w "$cpu/online" ]] && printf '0\n' >"$cpu/online" || true
    fi
  done
}

apply_common() {
  local boost="$1" min_freq="$2" max_freq="$3" cores="$4"
  [[ -n "$cores" ]] && set_cores "$cores"
  [[ -n "$boost" ]] && set_boost "$boost"
  [[ -n "$min_freq" || -n "$max_freq" ]] && set_freqs "$min_freq" "$max_freq"
  return 0
}

apply_ryzenadj_args() {
  local -a args=("$@")
  local arg failed=0 applied=0
  ((${#args[@]} > 0)) || return 0
  if ryzenadj_locked "${args[@]}" >/dev/null; then
    return 0
  fi

  printf 'Batch apply failed; retrying parameters one by one: %s\n' "${args[*]}" >&2
  for arg in "${args[@]}"; do
    if ryzenadj_locked "$arg" >/dev/null; then
      applied=1
    else
      failed=1
      printf 'Parameter apply failed: %s\n' "$arg" >&2
    fi
  done

  (( failed == 0 && applied == 1 ))
}

apply_defaults() {
  apply_ryzenadj_args \
    --stapm-limit="$BASE_STAPM_LIMIT" \
    --fast-limit="$BASE_FAST_LIMIT" \
    --slow-limit="$BASE_SLOW_LIMIT" \
    --apu-slow-limit="$BASE_APU_SLOW_LIMIT" \
    --vrm-current="$BASE_VRM_CURRENT" \
    --vrmsoc-current="$BASE_VRMSOC_CURRENT" \
    --vrmmax-current="$BASE_VRMMAX_CURRENT" \
    --vrmsocmax-current="$BASE_VRMSOCMAX_CURRENT" \
    --tctl-temp="$BASE_TCTL_TEMP"
}

array_contains() {
  local needle="$1" item
  shift
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

validate_percent() {
  local option="$1" value="$2"
  if [[ "$value" =~ ^([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]] &&
    awk -v value="$value" 'BEGIN { exit !(value > 0) }'; then
    return 0
  fi
  printf 'Invalid %s percentage: %s\n' "$option" "$value" >&2
  exit 2
}

parse_common_options() {
  INTERVAL="$DEFAULT_INTERVAL"
  LIMIT_PERCENT=100
  TEMP_PERCENT=100
  CURRENT_PERCENT=100
  BOOST_MODE=""
  MIN_FREQ=""
  MAX_FREQ=""
  CORES=""
  ONCE=0
  POSITIONAL=()
  PASSTHROUGH=()

  while (($#)); do
    case "$1" in
      --interval)
        INTERVAL="${2:?Missing value for --interval}"
        shift 2
        ;;
      --interval=*)
        INTERVAL="${1#*=}"
        shift
        ;;
      --limit)
        LIMIT_PERCENT="${2:?Missing value for --limit}"
        shift 2
        ;;
      --limit=*)
        LIMIT_PERCENT="${1#*=}"
        shift
        ;;
      --temp)
        TEMP_PERCENT="${2:?Missing value for --temp}"
        shift 2
        ;;
      --temp=*)
        TEMP_PERCENT="${1#*=}"
        shift
        ;;
      --current)
        CURRENT_PERCENT="${2:?Missing value for --current}"
        shift 2
        ;;
      --current=*)
        CURRENT_PERCENT="${1#*=}"
        shift
        ;;
      --boost)
        BOOST_MODE="${2:?Missing value for --boost}"
        shift 2
        ;;
      --boost=*)
        BOOST_MODE="${1#*=}"
        shift
        ;;
      --min-freq)
        MIN_FREQ="${2:?Missing value for --min-freq}"
        shift 2
        ;;
      --min-freq=*)
        MIN_FREQ="${1#*=}"
        shift
        ;;
      --max-freq)
        MAX_FREQ="${2:?Missing value for --max-freq}"
        shift 2
        ;;
      --max-freq=*)
        MAX_FREQ="${1#*=}"
        shift
        ;;
      --freq)
        MIN_FREQ="${2:?Missing value for --freq}"
        MAX_FREQ="$MIN_FREQ"
        shift 2
        ;;
      --freq=*)
        MIN_FREQ="${1#*=}"
        MAX_FREQ="$MIN_FREQ"
        shift
        ;;
      --cores)
        CORES="${2:?Missing value for --cores}"
        shift 2
        ;;
      --cores=*)
        CORES="${1#*=}"
        shift
        ;;
      --once)
        ONCE=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        shift
        PASSTHROUGH+=("$@")
        break
        ;;
      *)
        local item="$1" option
        option="${item%%=*}"
        option="${option#--}"
        if [[ "$item" == --*=* ]] && array_contains "$option" "${RYZEN_VALUE_OPTIONS[@]}"; then
          PASSTHROUGH+=("$item")
          shift
        elif [[ "$item" == --* ]] && array_contains "$option" "${RYZEN_VALUE_OPTIONS[@]}"; then
          PASSTHROUGH+=("--${option}=${2:?Missing value for --${option}}")
          shift 2
        elif [[ "$item" == --* ]] && array_contains "$option" "${RYZEN_FLAG_OPTIONS[@]}"; then
          PASSTHROUGH+=("--${option}")
          shift
        else
          POSITIONAL+=("$item")
          shift
        fi
        ;;
    esac
  done

  if ! [[ "$INTERVAL" =~ ^([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]] ||
    ! awk -v value="$INTERVAL" 'BEGIN { exit !(value >= 0.1) }'; then
    printf 'Invalid --interval (minimum 0.1): %s\n' "$INTERVAL" >&2
    exit 2
  fi
  validate_percent --limit "$LIMIT_PERCENT"
  validate_percent --temp "$TEMP_PERCENT"
  validate_percent --current "$CURRENT_PERCENT"
}

manual_args_from_positionals() {
  local -a out=()
  local item key value
  while ((${#POSITIONAL[@]})); do
    item="${POSITIONAL[0]}"
    POSITIONAL=("${POSITIONAL[@]:1}")
    case "$item" in
      --*=*)
        key="${item%%=*}"
        value="${item#*=}"
        out+=("$key=$value")
        ;;
      --*)
        case "$item" in
          --enable-oc|--disable-oc|--power-saving|--max-performance)
            out+=("$item")
            continue
            ;;
        esac
        value="${POSITIONAL[0]:-}"
        [[ -n "$value" ]] || { printf 'Missing value for %s\n' "$item" >&2; exit 2; }
        POSITIONAL=("${POSITIONAL[@]:1}")
        out+=("$item=$value")
        ;;
      *)
        printf 'Unexpected manual argument: %s\n' "$item" >&2
        exit 2
        ;;
    esac
  done
  printf '%s\n' "${out[@]}"
}

arg_key() {
  local arg="$1"
  arg="${arg%%=*}"
  printf '%s\n' "$arg"
}

merge_ryzen_args() {
  local -a base=()
  local -a overrides=()
  local arg override key skip

  while (($#)); do
    [[ "$1" == "--" ]] && { shift; break; }
    base+=("$1")
    shift
  done
  overrides=("$@")

  for arg in "${base[@]}"; do
    key="$(arg_key "$arg")"
    skip=0
    for override in "${overrides[@]}"; do
      if [[ "$(arg_key "$override")" == "$key" ]]; then
        skip=1
        break
      fi
    done
    (( skip == 0 )) && printf '%s\n' "$arg"
  done
  printf '%s\n' "${overrides[@]}"
}

normalize_ryzen_args() {
  local arg key parameter value
  for arg in "$@"; do
    if [[ "$arg" != --*=* ]]; then
      printf '%s\n' "$arg"
      continue
    fi
    key="${arg%%=*}"
    parameter="${key#--}"
    value="${arg#*=}"
    printf '%s=%s\n' "$key" "$(to_ryzen_unit "$parameter" "$value")"
  done
}

scale_group_args() {
  local limit_percent="$1" temp_percent="$2" current_percent="$3"
  shift 3
  local arg key parameter value percent
  for arg in "$@"; do
    if [[ "$arg" != --*=* ]]; then
      printf '%s\n' "$arg"
      continue
    fi
    key="${arg%%=*}"
    parameter="${key#--}"
    value="${arg#*=}"
    percent=100
    case "$parameter" in
      *-limit) percent="$limit_percent" ;;
      *-temp) percent="$temp_percent" ;;
      *-current|*_current) percent="$current_percent" ;;
    esac
    if [[ "$percent" != 100 ]]; then
      value="$(awk -v value="$value" -v percent="$percent" 'BEGIN { printf "%.0f", value * percent / 100 }')"
    fi
    printf '%s=%s\n' "$key" "$value"
  done
}

relative_args() {
  local parameter="${1:-}" target="${2:-}"
  local base target_unit ratio
  local stapm fast slow apu tctl vrm vrmsoc vrmmax vrmsocmax
  if [[ -z "$parameter" ]]; then
    ratio=1
  else
    [[ -n "${BASE_VALUES[$parameter]:-}" ]] || {
      printf 'Unsupported relative parameter: %s\n' "$parameter" >&2
      printf 'Supported: %s\n' "${!BASE_VALUES[*]}" >&2
      exit 2
    }
    base="${BASE_VALUES[$parameter]}"
    target_unit="$(to_ryzen_unit "$parameter" "$target")"
    if [[ "$parameter" == "tctl-temp" ]]; then
      (( target_unit >= 45 && target_unit <= BASE_TCTL_TEMP )) || {
        printf 'Temperature must be between 45 and %s C\n' "$BASE_TCTL_TEMP" >&2
        exit 2
      }
      ratio=1
    else
      ratio="$(awk -v t="$target_unit" -v b="$base" 'BEGIN { printf "%.10f\n", t / b }')"
    fi
  fi

  stapm="$(awk -v r="$ratio" -v b="$BASE_STAPM_LIMIT" 'BEGIN { printf "%.0f", b * r }')"
  fast="$(awk -v r="$ratio" -v b="$BASE_FAST_LIMIT" 'BEGIN { printf "%.0f", b * r }')"
  slow="$(awk -v r="$ratio" -v b="$BASE_SLOW_LIMIT" 'BEGIN { printf "%.0f", b * r }')"
  apu="$(awk -v r="$ratio" -v b="$BASE_APU_SLOW_LIMIT" 'BEGIN { printf "%.0f", b * r }')"
  vrm="$(awk -v r="$ratio" -v b="$BASE_VRM_CURRENT" 'BEGIN { printf "%.0f", b * r }')"
  vrmsoc="$(awk -v r="$ratio" -v b="$BASE_VRMSOC_CURRENT" 'BEGIN { printf "%.0f", b * r }')"
  vrmmax="$(awk -v r="$ratio" -v b="$BASE_VRMMAX_CURRENT" 'BEGIN { printf "%.0f", b * r }')"
  vrmsocmax="$(awk -v r="$ratio" -v b="$BASE_VRMSOCMAX_CURRENT" 'BEGIN { printf "%.0f", b * r }')"
  # Temperature is an independent safety limit, not a power/current ratio.
  tctl="$BASE_TCTL_TEMP"

  case "$parameter" in
    "") ;;
    stapm-limit) stapm="$target_unit" ;;
    fast-limit) fast="$target_unit" ;;
    slow-limit) slow="$target_unit" ;;
    apu-slow-limit) apu="$target_unit" ;;
    tctl-temp) tctl="$target_unit" ;;
    vrm-current) vrm="$target_unit" ;;
    vrmsoc-current) vrmsoc="$target_unit" ;;
    vrmmax-current) vrmmax="$target_unit" ;;
    vrmsocmax-current) vrmsocmax="$target_unit" ;;
  esac

  printf '%s\n' \
    "--stapm-limit=$stapm" \
    "--fast-limit=$fast" \
    "--slow-limit=$slow" \
    "--apu-slow-limit=$apu" \
    "--vrm-current=$vrm" \
    "--vrmsoc-current=$vrmsoc" \
    "--vrmmax-current=$vrmmax" \
    "--vrmsocmax-current=$vrmsocmax" \
    "--tctl-temp=$tctl"
}

write_profile() {
  local mode="$1" interval="$2" limit_percent="$3" temp_percent="$4" current_percent="$5"
  local boost="$6" min_freq="$7" max_freq="$8" cores="$9"
  shift 9
  local tmp arg parameter value
  tmp="$(mktemp "${RUNTIME_DIR}/profile.XXXXXX")"
  chmod 0600 "$tmp"
  {
    printf 'meta.mode=%s\n' "$mode"
    printf 'meta.interval=%s\n' "$interval"
    printf 'meta.limit-percent=%s\n' "$limit_percent"
    printf 'meta.temp-percent=%s\n' "$temp_percent"
    printf 'meta.current-percent=%s\n' "$current_percent"
    [[ -n "$boost" ]] && printf 'cpu.boost=%s\n' "$boost"
    [[ -n "$min_freq" ]] && printf 'cpu.min-freq=%s\n' "$min_freq"
    [[ -n "$max_freq" ]] && printf 'cpu.max-freq=%s\n' "$max_freq"
    [[ -n "$cores" ]] && printf 'cpu.cores=%s\n' "$cores"
    for arg in "$@"; do
      if [[ "$arg" == --*=* ]]; then
        parameter="${arg%%=*}"
        parameter="${parameter#--}"
        value="${arg#*=}"
        printf 'target.%s=%s\n' "$parameter" "$value"
      elif [[ "$arg" == --* ]]; then
        printf 'target.%s=on\n' "${arg#--}"
      fi
    done
  } >"$tmp"
  mv -f "$tmp" "$PROFILE_FILE"
}

read_profile() {
  local key value
  declare -gA PROFILE=()
  [[ -r "$PROFILE_FILE" ]] || return 0
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^(meta|cpu|target)\.[a-zA-Z0-9._-]+$ ]] || continue
    [[ "$value" =~ ^[a-zA-Z0-9._+-]+$ ]] || continue
    PROFILE["$key"]="$value"
  done <"$PROFILE_FILE"
}

parameter_unit() {
  case "$1" in
    *-limit) printf 'W' ;;
    *-temp) printf 'C' ;;
    *-current|*_current) printf 'A' ;;
    slow-time|stapm-time) printf 's' ;;
    *-frequency|max-vcn|min-vcn|max-lclk|min-lclk|max-gfxclk|min-gfxclk|gfx-clk|oc-clk) printf 'MHz' ;;
    oc-volt) printf 'VID' ;;
    *) printf '' ;;
  esac
}

format_target_value() {
  local parameter="$1" value="$2" unit
  [[ -n "$value" ]] || { printf '-'; return; }
  unit="$(parameter_unit "$parameter")"
  case "$parameter" in
    *-limit|*-current|*_current)
      awk -v value="$value" -v unit="$unit" 'BEGIN { printf "%.3f%s", value / 1000, unit }'
      ;;
    *) printf '%s%s' "$value" "$unit" ;;
  esac
}

format_actual_value() {
  local parameter="$1" value="$2" unit
  [[ -n "$value" ]] || { printf 'n/a'; return; }
  unit="$(parameter_unit "$parameter")"
  printf '%s%s' "$value" "$unit"
}

status_cell() {
  local parameter="$1" target actual
  if [[ -z "$parameter" ]]; then
    printf '%-25s %-13s %-13s' '' '' ''
    return
  fi
  target="$(format_target_value "$parameter" "${PROFILE[target.${parameter}]:-}")"
  actual="$(format_actual_value "$parameter" "${ACTUAL[$parameter]:-}")"
  printf '%-25s %-13s %-13s' "$parameter" "$target" "$actual"
}

policy_values() {
  local filename="$1" policy value
  for policy in /sys/devices/system/cpu/cpufreq/policy*; do
    policy_is_online "$policy" || continue
    [[ -r "$policy/$filename" ]] || continue
    value="$(<"$policy/$filename")"
    printf '%s\n' "$value"
  done | sort -u | paste -sd, -
}

dpm_current_mhz() {
  local file="$1"
  [[ -r "$file" ]] || { printf 'n/a'; return; }
  awk '/\*/ { for (i = 1; i <= NF; i++) if ($i ~ /Mhz/) { gsub(/Mhz/, "", $i); print $i; exit } }' "$file"
}

status() {
  local info name value parameter i right gpu hwmon gfx_clock
  declare -A ACTUAL=()
  read_profile
  info="$(ryzen_info || true)"
  while IFS='|' read -r _ name value parameter _; do
    name="${name#"${name%%[![:space:]]*}"}"; name="${name%"${name##*[![:space:]]}"}"
    value="${value#"${value%%[![:space:]]*}"}"; value="${value%"${value##*[![:space:]]}"}"
    parameter="${parameter#"${parameter%%[![:space:]]*}"}"; parameter="${parameter%"${parameter##*[![:space:]]}"}"
    [[ "$name" != CCLK* ]] || continue
    [[ -n "$parameter" && "$parameter" != "Parameter" && "$parameter" != *' '* ]] || continue
    ACTUAL["$parameter"]="$value"
  done <<<"$info"
  for gpu in /sys/class/drm/card*/device; do
    [[ -r "$gpu/pp_dpm_sclk" ]] || continue
    gfx_clock="$(dpm_current_mhz "$gpu/pp_dpm_sclk")"
    [[ "$gfx_clock" != n/a && -n "$gfx_clock" ]] && ACTUAL[gfx-clk]="$gfx_clock"
    break
  done

  if systemctl is-active --quiet "$UNIT_NAME"; then
    printf 'enforcer=active  unit=%s\n' "$UNIT_NAME"
  else
    printf 'enforcer=inactive  unit=%s\n' "$UNIT_NAME"
  fi
  if [[ -n "${PROFILE[meta.interval]:-}" ]]; then
    printf 'mode=%s  interval=%ss  limit=%s%%  temp=%s%%  current=%s%%\n' \
      "${PROFILE[meta.mode]:-none}" "${PROFILE[meta.interval]}" \
      "${PROFILE[meta.limit-percent]:-100}" "${PROFILE[meta.temp-percent]:-100}" \
      "${PROFILE[meta.current-percent]:-100}"
  else
    printf 'mode=%s  interval=-  limit=%s%%  temp=%s%%  current=%s%%\n' \
      "${PROFILE[meta.mode]:-none}" "${PROFILE[meta.limit-percent]:-100}" \
      "${PROFILE[meta.temp-percent]:-100}" "${PROFILE[meta.current-percent]:-100}"
  fi

  printf '\n%-25s %-13s %-13s | %-25s %-13s %-13s\n' \
    'RYZENADJ PARAMETER' 'TARGET' 'ACTUAL' 'RYZENADJ PARAMETER' 'TARGET' 'ACTUAL'
  for ((i = 0; i < ${#STATUS_PARAMETERS[@]}; i += 2)); do
    right="${STATUS_PARAMETERS[i + 1]:-}"
    status_cell "${STATUS_PARAMETERS[i]}"
    printf ' | '
    status_cell "$right"
    printf '\n'
  done

  printf '\nCPU CONTROL          TARGET        ACTUAL\n'
  printf '%-20s %-13s %s\n' boost "${PROFILE[cpu.boost]:--}" "$(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || printf 'n/a')"
  printf '%-20s %-13s %s\n' min-freq "${PROFILE[cpu.min-freq]:--}" "$(policy_values scaling_min_freq)"
  printf '%-20s %-13s %s\n' max-freq "${PROFILE[cpu.max-freq]:--}" "$(policy_values scaling_max_freq)"
  printf '%-20s %-13s %s\n' cores "${PROFILE[cpu.cores]:--}" "$(cat /sys/devices/system/cpu/online 2>/dev/null || printf 'n/a')"
  printf '%-20s %-13s %s\n' governor '-' "$(policy_values scaling_governor)"

  if [[ -n "${gpu:-}" && -d "$gpu" ]]; then
    printf '\nIGPU TELEMETRY\n'
    printf '%-24s %sMHz\n' gfxclk "$(dpm_current_mhz "$gpu/pp_dpm_sclk")"
    printf '%-24s %sMHz\n' socclk "$(dpm_current_mhz "$gpu/pp_dpm_socclk")"
    printf '%-24s %sMHz\n' fclk "$(dpm_current_mhz "$gpu/pp_dpm_fclk")"
    printf '%-24s %sMHz\n' mclk "$(dpm_current_mhz "$gpu/pp_dpm_mclk")"
    printf '%-24s %s%%\n' gpu-busy "$(cat "$gpu/gpu_busy_percent" 2>/dev/null || printf 'n/a')"
    for hwmon in "$gpu"/hwmon/hwmon*; do
      [[ -r "$hwmon/temp1_input" ]] || continue
      awk -v value="$(<"$hwmon/temp1_input")" 'BEGIN { printf "%-24s %.1fC\n", "gpu-temperature", value / 1000 }'
      break
    done
  fi

  printf '\nLIVE METRICS\n'
  while IFS='|' read -r _ name value parameter _; do
    name="${name#"${name%%[![:space:]]*}"}"; name="${name%"${name##*[![:space:]]}"}"
    value="${value#"${value%%[![:space:]]*}"}"; value="${value%"${value##*[![:space:]]}"}"
    [[ "$name" == *' VALUE'* || "$name" == 'CCLK BUSY VALUE' ]] || continue
    printf '%-24s %s\n' "$name" "$value"
  done <<<"$info"
}

start_enforcer() {
  local interval="$1"
  shift
  systemd-run --system --quiet --collect --unit="$UNIT_NAME" \
    --setenv="PATH=$SYSTEM_PATH" \
    --property=Type=simple \
    --property=Restart=on-failure \
    --property=RestartSec=2s \
    --property=SyslogIdentifier=ryzenadj-mode \
    "$BASH" "$SCRIPT_PATH" _enforce "$interval" "$@"
}

stop_enforcer() {
  systemctl stop "$UNIT_NAME" >/dev/null 2>&1 || true
  systemctl reset-failed "$UNIT_NAME" >/dev/null 2>&1 || true
  return 0
}

restore_state() {
  [[ -r "$STATE_FILE" ]] || return 0
  local key value
  declare -A state=()
  local -a restore_args
  local policy index var cpu
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^(STAPM_LIMIT|FAST_LIMIT|SLOW_LIMIT|SLOW_TIME|STAPM_TIME|APU_SLOW_LIMIT|TCTL_TEMP|APU_SKIN_TEMP|DGPU_SKIN_TEMP|VRM_CURRENT|VRMSOC_CURRENT|VRMMAX_CURRENT|VRMSOCMAX_CURRENT|BOOST|GOV_[0-9]+|MIN_[0-9]+|MAX_[0-9]+|CPU_[0-9]+)$ ]] || {
      printf 'Invalid state key: %s\n' "$key" >&2; return 1;
    }
    [[ "$value" =~ ^[a-zA-Z0-9._+-]+$ ]] || { printf 'Invalid state value for %s\n' "$key" >&2; return 1; }
    state["$key"]="$value"
  done <"$STATE_FILE"

  if [[ -n "${state[STAPM_LIMIT]:-}" && -n "${state[FAST_LIMIT]:-}" && -n "${state[SLOW_LIMIT]:-}" && -n "${state[APU_SLOW_LIMIT]:-}" && -n "${state[TCTL_TEMP]:-}" ]]; then
    restore_args=(
      "--stapm-limit=$(to_ryzen_unit stapm-limit "${state[STAPM_LIMIT]}")"
      "--fast-limit=$(to_ryzen_unit fast-limit "${state[FAST_LIMIT]}")"
      "--slow-limit=$(to_ryzen_unit slow-limit "${state[SLOW_LIMIT]}")"
      "--apu-slow-limit=$(to_ryzen_unit apu-slow-limit "${state[APU_SLOW_LIMIT]}")"
      "--tctl-temp=$(to_ryzen_unit tctl-temp "${state[TCTL_TEMP]}")"
    )
    [[ -n "${state[SLOW_TIME]:-}" ]] && restore_args+=("--slow-time=$(to_ryzen_unit slow-time "${state[SLOW_TIME]}")")
    [[ -n "${state[STAPM_TIME]:-}" ]] && restore_args+=("--stapm-time=$(to_ryzen_unit stapm-time "${state[STAPM_TIME]}")")
    [[ -n "${state[APU_SKIN_TEMP]:-}" ]] && restore_args+=("--apu-skin-temp=$(to_ryzen_unit apu-skin-temp "${state[APU_SKIN_TEMP]}")")
    [[ -n "${state[DGPU_SKIN_TEMP]:-}" ]] && restore_args+=("--dgpu-skin-temp=$(to_ryzen_unit dgpu-skin-temp "${state[DGPU_SKIN_TEMP]}")")
    [[ -n "${state[VRM_CURRENT]:-}" ]] && restore_args+=("--vrm-current=$(to_ryzen_unit vrm-current "${state[VRM_CURRENT]}")")
    [[ -n "${state[VRMSOC_CURRENT]:-}" ]] && restore_args+=("--vrmsoc-current=$(to_ryzen_unit vrmsoc-current "${state[VRMSOC_CURRENT]}")")
    [[ -n "${state[VRMMAX_CURRENT]:-}" ]] && restore_args+=("--vrmmax-current=$(to_ryzen_unit vrmmax-current "${state[VRMMAX_CURRENT]}")")
    [[ -n "${state[VRMSOCMAX_CURRENT]:-}" ]] && restore_args+=("--vrmsocmax-current=$(to_ryzen_unit vrmsocmax-current "${state[VRMSOCMAX_CURRENT]}")")
    ryzenadj_locked "${restore_args[@]}" >/dev/null || true
  fi
  [[ -n "${state[BOOST]:-}" ]] && set_boost "${state[BOOST]}" || true

  for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    [[ -w "$cpu/online" ]] || continue
    index="${cpu##*cpu}"
    var="CPU_${index}"
    [[ -n "${state[$var]:-}" ]] && printf '%s\n' "${state[$var]}" >"$cpu/online" || true
  done
  for policy in /sys/devices/system/cpu/cpufreq/policy*; do
    [[ -d "$policy" ]] || continue
    index="${policy##*policy}"
    local saved_min="${state[MIN_${index}]:-}" saved_max="${state[MAX_${index}]:-}"
    if [[ -n "$saved_max" && "$saved_max" -lt "$(<"$policy/scaling_min_freq")" ]]; then
      [[ -n "$saved_min" && -w "$policy/scaling_min_freq" ]] && printf '%s\n' "$saved_min" >"$policy/scaling_min_freq"
      [[ -w "$policy/scaling_max_freq" ]] && printf '%s\n' "$saved_max" >"$policy/scaling_max_freq"
    else
      [[ -n "$saved_max" && -w "$policy/scaling_max_freq" ]] && printf '%s\n' "$saved_max" >"$policy/scaling_max_freq"
      [[ -n "$saved_min" && -w "$policy/scaling_min_freq" ]] && printf '%s\n' "$saved_min" >"$policy/scaling_min_freq"
    fi
    var="GOV_${index}"
    [[ -n "${state[$var]:-}" && -w "$policy/scaling_governor" ]] && printf '%s\n' "${state[$var]}" >"$policy/scaling_governor"
  done

  rm -f "$STATE_FILE"
}

cmd="${1:---help}"
shift || true

case "$cmd" in
  _enforce)
    need_root _enforce "$@"
    init_runtime_dir
    INTERVAL="${1:?Missing enforcement interval}"
    shift
    export RYZENADJ_MODE_ENFORCER=1
    printf '%s started interval=%s command=%q\n' "$(date --iso-8601=seconds)" "$INTERVAL" "$*"
    while :; do
      if "$@"; then
        :
      else
        code="$?"
        printf '%s command failed code=%s command=%q\n' "$(date --iso-8601=seconds)" "$code" "$*" >&2
      fi
      sleep "$INTERVAL"
    done
    ;;
  --help|help|-h)
    usage
    ;;
  --status|status)
    need_root --status "$@"
    init_runtime_dir
    status
    ;;
  stop|restore)
    need_root "$cmd" "$@"
    init_runtime_dir
    stop_enforcer
    restore_state
    rm -f "$PROFILE_FILE"
    printf 'Stopped %s and restored the saved readable state.\n' "$UNIT_NAME"
    ;;
  defaults|default|reset-defaults)
    need_root "$cmd" "$@"
    init_runtime_dir
    stop_enforcer
    apply_defaults
    rm -f "$STATE_FILE"
    write_profile defaults 0 100 100 100 '' '' '' '' \
      --stapm-limit="$BASE_STAPM_LIMIT" \
      --fast-limit="$BASE_FAST_LIMIT" \
      --slow-limit="$BASE_SLOW_LIMIT" \
      --apu-slow-limit="$BASE_APU_SLOW_LIMIT" \
      --vrm-current="$BASE_VRM_CURRENT" \
      --vrmsoc-current="$BASE_VRMSOC_CURRENT" \
      --vrmmax-current="$BASE_VRMMAX_CURRENT" \
      --vrmsocmax-current="$BASE_VRMSOCMAX_CURRENT" \
      --tctl-temp="$BASE_TCTL_TEMP"
    printf 'Stopped %s and applied configured defaults.\n' "$UNIT_NAME"
    ;;
  manual)
    need_root manual "$@"
    init_runtime_dir
    parse_common_options "$@"
    POSITIONAL+=("${PASSTHROUGH[@]}")
    mapfile -t RYZEN_ARGS < <(manual_args_from_positionals)
    ((${#RYZEN_ARGS[@]} > 0)) || { printf 'manual mode requires ryzenadj options\n' >&2; exit 2; }
    mapfile -t RYZEN_ARGS < <(normalize_ryzen_args "${RYZEN_ARGS[@]}")
    mapfile -t RYZEN_ARGS < <(scale_group_args "$LIMIT_PERCENT" "$TEMP_PERCENT" "$CURRENT_PERCENT" "${RYZEN_ARGS[@]}")
    [[ "${RYZENADJ_MODE_ENFORCER:-0}" == "1" ]] || stop_enforcer
    save_state
    apply_common "$BOOST_MODE" "$MIN_FREQ" "$MAX_FREQ" "$CORES"
    apply_ryzenadj_args "${RYZEN_ARGS[@]}"
    [[ "${RYZENADJ_MODE_ENFORCER:-0}" == "1" ]] && exit 0
    write_profile manual "$INTERVAL" "$LIMIT_PERCENT" "$TEMP_PERCENT" "$CURRENT_PERCENT" \
      "$BOOST_MODE" "$MIN_FREQ" "$MAX_FREQ" "$CORES" "${RYZEN_ARGS[@]}"
    if (( ONCE == 0 )); then
      ENFORCER_ARGS=("$BASH" "$SCRIPT_PATH" manual --once)
      [[ -n "$BOOST_MODE" ]] && ENFORCER_ARGS+=(--boost "$BOOST_MODE")
      [[ -n "$MIN_FREQ" ]] && ENFORCER_ARGS+=(--min-freq "$MIN_FREQ")
      [[ -n "$MAX_FREQ" ]] && ENFORCER_ARGS+=(--max-freq "$MAX_FREQ")
      [[ -n "$CORES" ]] && ENFORCER_ARGS+=(--cores "$CORES")
      ENFORCER_ARGS+=(-- "${RYZEN_ARGS[@]}")
      start_enforcer "$INTERVAL" "${ENFORCER_ARGS[@]}"
    fi
    printf 'Applied manual profile%s. Use ryzenadj-mode --status for details.\n' "$([[ "$ONCE" -eq 0 ]] && printf ' with enforcement' || true)"
    ;;
  relative)
    need_root relative "$@"
    init_runtime_dir
    parse_common_options "$@"
    ((${#POSITIONAL[@]} == 0 || ${#POSITIONAL[@]} == 2)) || {
      printf 'relative mode accepts either no positional values or: <parameter> <value>\n' >&2
      exit 2
    }
    RELATIVE_PARAMETER="${POSITIONAL[0]:-}"
    RELATIVE_VALUE="${POSITIONAL[1]:-}"
    mapfile -t RYZEN_ARGS < <(relative_args "$RELATIVE_PARAMETER" "$RELATIVE_VALUE")
    if ((${#PASSTHROUGH[@]} > 0)); then
      POSITIONAL=("${PASSTHROUGH[@]}")
      mapfile -t OVERRIDE_ARGS < <(manual_args_from_positionals)
      mapfile -t RYZEN_ARGS < <(merge_ryzen_args "${RYZEN_ARGS[@]}" -- "${OVERRIDE_ARGS[@]}")
    fi
    mapfile -t RYZEN_ARGS < <(normalize_ryzen_args "${RYZEN_ARGS[@]}")
    mapfile -t RYZEN_ARGS < <(scale_group_args "$LIMIT_PERCENT" "$TEMP_PERCENT" "$CURRENT_PERCENT" "${RYZEN_ARGS[@]}")
    [[ "${RYZENADJ_MODE_ENFORCER:-0}" == "1" ]] || stop_enforcer
    save_state
    apply_common "$BOOST_MODE" "$MIN_FREQ" "$MAX_FREQ" "$CORES"
    apply_ryzenadj_args "${RYZEN_ARGS[@]}"
    [[ "${RYZENADJ_MODE_ENFORCER:-0}" == "1" ]] && exit 0
    write_profile relative "$INTERVAL" "$LIMIT_PERCENT" "$TEMP_PERCENT" "$CURRENT_PERCENT" \
      "$BOOST_MODE" "$MIN_FREQ" "$MAX_FREQ" "$CORES" "${RYZEN_ARGS[@]}"
    if (( ONCE == 0 )); then
      ENFORCER_ARGS=("$BASH" "$SCRIPT_PATH" manual --once)
      [[ -n "$BOOST_MODE" ]] && ENFORCER_ARGS+=(--boost "$BOOST_MODE")
      [[ -n "$MIN_FREQ" ]] && ENFORCER_ARGS+=(--min-freq "$MIN_FREQ")
      [[ -n "$MAX_FREQ" ]] && ENFORCER_ARGS+=(--max-freq "$MAX_FREQ")
      [[ -n "$CORES" ]] && ENFORCER_ARGS+=(--cores "$CORES")
      ENFORCER_ARGS+=(-- "${RYZEN_ARGS[@]}")
      start_enforcer "$INTERVAL" "${ENFORCER_ARGS[@]}"
    fi
    printf 'Applied relative profile%s. Use ryzenadj-mode --status for details.\n' "$([[ "$ONCE" -eq 0 ]] && printf ' with enforcement' || true)"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
