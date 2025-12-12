#!/usr/bin/env bash
# Shimmer Animation Demo with Color Configuration
# Based on the algorithm in codex-rs/tui2/src/shimmer.rs
#
# This script demonstrates the shimmer animation with configurable colors.
# Use it to test color configurations before applying to prepare-commit-msg hook.

set -euo pipefail

# =============================================================================
# Color Configuration (these will become environment variables in the hook)
# =============================================================================

# Shimmer animation colors (256-color mode: 0-255, or TrueColor: "R,G,B")
# Base color: the bright default text color
LLM_GITHOOK_SHIMMER_BASE_COLOR="${LLM_GITHOOK_SHIMMER_BASE_COLOR:-120}"
# Highlight color: the dim "wave" color that sweeps across
LLM_GITHOOK_SHIMMER_HIGHLIGHT_COLOR="${LLM_GITHOOK_SHIMMER_HIGHLIGHT_COLOR:-103}"

# Spinner color: defaults to match shimmer base color for visual consistency
# (256-color mode: 0-255, or named: red, green, yellow, blue, magenta, cyan, white)
LLM_GITHOOK_SPINNER_COLOR="${LLM_GITHOOK_SPINNER_COLOR:-$LLM_GITHOOK_SHIMMER_BASE_COLOR}"

# Animation parameters
LLM_GITHOOK_SHIMMER_SWEEP_SECONDS="${LLM_GITHOOK_SHIMMER_SWEEP_SECONDS:-2.0}"
LLM_GITHOOK_SHIMMER_PADDING="${LLM_GITHOOK_SHIMMER_PADDING:-10}"
LLM_GITHOOK_SHIMMER_BAND_WIDTH="${LLM_GITHOOK_SHIMMER_BAND_WIDTH:-5.0}"
LLM_GITHOOK_FPS="${LLM_GITHOOK_FPS:-30}"
LLM_GITHOOK_STATUS_TEXT="${LLM_GITHOOK_STATUS_TEXT:-Generating commit message...}"
LLM_GITHOOK_SPINNER_STYLE="${LLM_GITHOOK_SPINNER_STYLE:-dots}"

# Color mode: "256" for 256-color palette, "truecolor" for 24-bit RGB
LLM_GITHOOK_COLOR_MODE="${LLM_GITHOOK_COLOR_MODE:-256}"

# =============================================================================
# Helper Functions
# =============================================================================

# Detect TrueColor support
detect_truecolor_support() {
  # Check COLORTERM environment variable
  if [[ "${COLORTERM:-}" == "truecolor" ]] || [[ "${COLORTERM:-}" == "24bit" ]]; then
    return 0
  fi
  # Check TERM for known TrueColor terminals
  case "${TERM:-}" in
    *-truecolor|*-24bit|xterm-256color|screen-256color|tmux-256color)
      # Many modern terminals support TrueColor even with 256color TERM
      return 0
      ;;
  esac
  return 1
}

# Parse color value - returns ANSI escape sequence for foreground color
# Input: color name, 256-color number, or "R,G,B" for TrueColor
# Output: ANSI escape sequence (without \033[ prefix and m suffix)
parse_color() {
  local color="$1"
  local mode="${2:-256}"

  # Named colors
  case "$color" in
    black)   echo "30" ; return ;;
    red)     echo "31" ; return ;;
    green)   echo "32" ; return ;;
    yellow)  echo "33" ; return ;;
    blue)    echo "34" ; return ;;
    magenta) echo "35" ; return ;;
    cyan)    echo "36" ; return ;;
    white)   echo "37" ; return ;;
  esac

  # TrueColor RGB format: "R,G,B"
  if [[ "$color" == *,*,* ]]; then
    local r g b
    IFS=',' read -r r g b <<< "$color"
    echo "38;2;$r;$g;$b"
    return
  fi

  # 256-color number
  if [[ "$color" =~ ^[0-9]+$ ]]; then
    echo "38;5;$color"
    return
  fi

  # Fallback to white
  echo "37"
}

# Get ANSI escape code for spinner color
get_spinner_ansi() {
  local color="$LLM_GITHOOK_SPINNER_COLOR"
  local code
  code=$(parse_color "$color")
  printf '\033[%sm' "$code"
}

# Available spinner styles
SPINNER_STYLES=(
  "classic|/-\\"
  "dots|⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
  "arrows|←↖↑↗→↘↓↙"
  "blocks|▖▘▝▗"
  "pulse|▁▂▃▄▅▆▇█▇▆▅▄▃▂"
  "bouncing|⠁⠂⠄⡀⢀⠠⠐⠈"
  "circle|◐◓◑◒"
  "square|◰◳◲◱"
  "triangle|◴◵◶◷"
  "diamond|◇◈◆"
)

# Function to get spinner characters based on style
get_spinner_chars() {
  local style_name="${1:-classic}"

  for style in "${SPINNER_STYLES[@]}"; do
    if [[ "$style" == "$style_name"* ]]; then
      echo "$style" | cut -d'|' -f2
      return 0
    fi
  done

  # Fallback to classic if style not found
  echo "|/-\\"
}

# Detect the best available high-resolution time source
detect_time_provider() {
  if command -v gdate >/dev/null 2>&1; then
    echo "gdate"
    return 0
  fi

  if perl -MTime::HiRes -e 'exit 0' >/dev/null 2>&1; then
    echo "perl"
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    echo "python3"
    return 0
  fi

  echo "date"
}

TIME_PROVIDER="$(detect_time_provider)"

get_time() {
  case "$TIME_PROVIDER" in
    gdate) gdate +%s.%N ;;
    perl) perl -MTime::HiRes=time -e 'printf "%.9f\n", time()' ;;
    python3) python3 -c 'import time; print(f"{time.time():.9f}")' ;;
    *) date +%s ;;
  esac
}

# =============================================================================
# Shimmer Rendering Functions
# =============================================================================

# Render shimmer text using 256-color grayscale interpolation
render_shimmer_256() {
  local text="$1"
  local now="$2"
  local start="$3"
  local base_color="$LLM_GITHOOK_SHIMMER_BASE_COLOR"
  local highlight_color="$LLM_GITHOOK_SHIMMER_HIGHLIGHT_COLOR"

  printf '%s %s\n' "$now" "$start" | awk \
    -v text="$text" \
    -v sweep="$LLM_GITHOOK_SHIMMER_SWEEP_SECONDS" \
    -v pad="$LLM_GITHOOK_SHIMMER_PADDING" \
    -v width="$LLM_GITHOOK_SHIMMER_BAND_WIDTH" \
    -v base="$base_color" \
    -v highlight="$highlight_color" '
    {
      now = $1;
      start = $2;
      len = length(text);
      period = len + (pad * 2);

      elapsed = now - start;
      pos_f = (elapsed % sweep) / sweep;
      center = pos_f * period;

      output = "";

      for (i = 0; i < len; i++) {
        i_pos = i + pad;
        dist = i_pos - center;
        if (dist < 0) dist = -dist;

        intensity = 0.0;
        if (dist <= width) {
          x = 3.14159 * (dist / width);
          intensity = 0.5 * (1.0 + cos(x));
        }

        # Interpolate between base and highlight colors
        color_val = int(base + (intensity * (highlight - base)));

        # Clamp to valid 256-color range
        if (color_val > 255) color_val = 255;
        if (color_val < 0) color_val = 0;

        output = output sprintf("\033[38;5;%dm%s", color_val, substr(text, i+1, 1));
      }

      output = output "\033[0m";
      print output;
    }'
}

# Render shimmer text using TrueColor (24-bit RGB) interpolation
render_shimmer_truecolor() {
  local text="$1"
  local now="$2"
  local start="$3"
  local base_color="$LLM_GITHOOK_SHIMMER_BASE_COLOR"
  local highlight_color="$LLM_GITHOOK_SHIMMER_HIGHLIGHT_COLOR"

  # Parse RGB values from "R,G,B" format or convert 256-color to approximate RGB
  local base_r base_g base_b
  local highlight_r highlight_g highlight_b

  if [[ "$base_color" == *,*,* ]]; then
    IFS=',' read -r base_r base_g base_b <<< "$base_color"
  else
    # Convert 256-color grayscale to RGB
    if [[ "$base_color" -ge 232 && "$base_color" -le 255 ]]; then
      local gray_val=$(( (base_color - 232) * 10 + 8 ))
      base_r=$gray_val; base_g=$gray_val; base_b=$gray_val
    else
      base_r=128; base_g=128; base_b=128
    fi
  fi

  if [[ "$highlight_color" == *,*,* ]]; then
    IFS=',' read -r highlight_r highlight_g highlight_b <<< "$highlight_color"
  else
    if [[ "$highlight_color" -ge 232 && "$highlight_color" -le 255 ]]; then
      local gray_val=$(( (highlight_color - 232) * 10 + 8 ))
      highlight_r=$gray_val; highlight_g=$gray_val; highlight_b=$gray_val
    else
      highlight_r=255; highlight_g=255; highlight_b=255
    fi
  fi

  printf '%s %s\n' "$now" "$start" | awk \
    -v text="$text" \
    -v sweep="$LLM_GITHOOK_SHIMMER_SWEEP_SECONDS" \
    -v pad="$LLM_GITHOOK_SHIMMER_PADDING" \
    -v width="$LLM_GITHOOK_SHIMMER_BAND_WIDTH" \
    -v base_r="$base_r" -v base_g="$base_g" -v base_b="$base_b" \
    -v hi_r="$highlight_r" -v hi_g="$highlight_g" -v hi_b="$highlight_b" '
    {
      now = $1;
      start = $2;
      len = length(text);
      period = len + (pad * 2);

      elapsed = now - start;
      pos_f = (elapsed % sweep) / sweep;
      center = pos_f * period;

      output = "";

      for (i = 0; i < len; i++) {
        i_pos = i + pad;
        dist = i_pos - center;
        if (dist < 0) dist = -dist;

        intensity = 0.0;
        if (dist <= width) {
          x = 3.14159 * (dist / width);
          intensity = 0.5 * (1.0 + cos(x));
        }

        # Linear interpolation between base and highlight RGB
        r = int(base_r + (intensity * (hi_r - base_r)));
        g = int(base_g + (intensity * (hi_g - base_g)));
        b = int(base_b + (intensity * (hi_b - base_b)));

        # Clamp values
        if (r > 255) r = 255; if (r < 0) r = 0;
        if (g > 255) g = 255; if (g < 0) g = 0;
        if (b > 255) b = 255; if (b < 0) b = 0;

        output = output sprintf("\033[38;2;%d;%d;%dm%s", r, g, b, substr(text, i+1, 1));
      }

      output = output "\033[0m";
      print output;
    }'
}

# Main shimmer render function - dispatches to appropriate renderer
render_shimmer_text() {
  local text="$1"
  local now="$2"
  local start="$3"

  if [[ "$LLM_GITHOOK_COLOR_MODE" == "truecolor" ]]; then
    render_shimmer_truecolor "$text" "$now" "$start"
  else
    render_shimmer_256 "$text" "$now" "$start"
  fi
}

# =============================================================================
# Main Spinner/Animation Loop
# =============================================================================

spinner() {
  local style="${LLM_GITHOOK_SPINNER_STYLE:-classic}"
  local spinner_chars
  spinner_chars=$(get_spinner_chars "$style")
  local -a spinner_frames=()

  # Unicode-safe spinner frames
  if command -v python3 >/dev/null 2>&1; then
    while IFS= read -r _frame; do
      spinner_frames+=("$_frame")
    done < <(SPINNER_CHARS="$spinner_chars" python3 -c '
import os, sys
s = os.environ.get("SPINNER_CHARS", "")
for ch in s:
    sys.stdout.write(ch + "\n")
')
  fi
  if [ "${#spinner_frames[@]}" -eq 0 ]; then
    local j
    for ((j = 0; j < ${#spinner_chars}; j++)); do
      spinner_frames+=("${spinner_chars:j:1}")
    done
  fi

  local start_time
  start_time="$(get_time)"

  local fps="${LLM_GITHOOK_FPS:-30}"
  local frame_interval
  frame_interval="$(awk -v fps="$fps" 'BEGIN{ if (fps <= 0) fps = 30; printf "%.6f", (1.0 / fps) }')"

  local spinner_ansi
  spinner_ansi=$(get_spinner_ansi)
  local nc=$'\033[0m'

  local i=0

  while :; do
    local char="${spinner_frames[i]}"
    local now
    now="$(get_time)"
    local shimmered
    shimmered="$(render_shimmer_text "$LLM_GITHOOK_STATUS_TEXT" "$now" "$start_time")"

    # Clear the line and redraw in-place
    printf "\r\033[K%s%s%s %s" "$spinner_ansi" "$char" "$nc" "$shimmered"

    ((i = (i + 1) % ${#spinner_frames[@]}))
    sleep "$frame_interval"
  done
}

# =============================================================================
# Demo Mode
# =============================================================================

show_help() {
  cat << 'EOF'
Shimmer Animation Demo - Color Configuration Test

Usage: ./shimmer-demo.sh [options]

Environment Variables for Color Configuration:

  SHIMMER ANIMATION:
    LLM_GITHOOK_SHIMMER_BASE_COLOR      Base (bright) color (default: 255)
    LLM_GITHOOK_SHIMMER_HIGHLIGHT_COLOR Highlight (dim wave) color (default: 240)

    Color formats:
    - 256-color mode: 0-255 (grayscale: 232-255)
    - TrueColor mode: "R,G,B" (e.g., "100,150,200")

  SPINNER:
    LLM_GITHOOK_SPINNER_COLOR           Spinner color (default: same as base)

    Color formats:
    - Named: black, red, green, yellow, blue, magenta, cyan, white
    - 256-color: 0-255
    - TrueColor: "R,G,B"

  ANIMATION PARAMETERS:
    LLM_GITHOOK_SHIMMER_SWEEP_SECONDS   Duration of one sweep (default: 2.0)
    LLM_GITHOOK_SHIMMER_PADDING         Padding characters (default: 10)
    LLM_GITHOOK_SHIMMER_BAND_WIDTH      Width of glow band (default: 5.0)
    LLM_GITHOOK_FPS                     Frames per second (default: 30)
    LLM_GITHOOK_STATUS_TEXT             Text to display
    LLM_GITHOOK_SPINNER_STYLE           Spinner style (default: dots)

  COLOR MODE:
    LLM_GITHOOK_COLOR_MODE              "256" or "truecolor" (default: 256)

Examples:

  # Blue theme (bright cyan base, dark blue wave)
  LLM_GITHOOK_SHIMMER_BASE_COLOR=51 \
  LLM_GITHOOK_SHIMMER_HIGHLIGHT_COLOR=17 \
  ./shimmer-demo.sh

  # TrueColor gradient (bright pink base, dark purple wave)
  LLM_GITHOOK_COLOR_MODE=truecolor \
  LLM_GITHOOK_SHIMMER_BASE_COLOR="255,100,200" \
  LLM_GITHOOK_SHIMMER_HIGHLIGHT_COLOR="80,40,120" \
  ./shimmer-demo.sh

  # Green theme (bright green base, dark green wave)
  LLM_GITHOOK_SHIMMER_BASE_COLOR=46 \
  LLM_GITHOOK_SHIMMER_HIGHLIGHT_COLOR=22 \
  ./shimmer-demo.sh

Press Ctrl+C to exit the demo.
EOF
}

# Mock git operation simulation
mock_git_operation() {
  local duration="${1:-5}"
  echo "Simulating git commit operation for ${duration} seconds..."
  echo ""
  sleep "$duration"
}

# =============================================================================
# Main Entry Point
# =============================================================================

main() {
  if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
    exit 0
  fi

  echo "Shimmer Animation Demo"
  echo "======================"
  echo ""
  echo "Current Configuration:"
  echo "  Color Mode:      $LLM_GITHOOK_COLOR_MODE"
  echo "  Base Color:      $LLM_GITHOOK_SHIMMER_BASE_COLOR"
  echo "  Highlight Color: $LLM_GITHOOK_SHIMMER_HIGHLIGHT_COLOR"
  echo "  Spinner Color:   $LLM_GITHOOK_SPINNER_COLOR"
  echo "  Spinner Style:   $LLM_GITHOOK_SPINNER_STYLE"
  echo "  FPS:             $LLM_GITHOOK_FPS"
  echo "  Sweep Seconds:   $LLM_GITHOOK_SHIMMER_SWEEP_SECONDS"
  echo ""
  echo "Press Ctrl+C to exit."
  echo ""

  # Hide cursor
  printf '\033[?25l'

  # Cleanup on exit
  trap 'printf "\033[?25h"; printf "\r\033[K"; echo ""; exit 0' SIGINT SIGTERM EXIT

  # Start the spinner animation
  spinner
}

main "$@"
