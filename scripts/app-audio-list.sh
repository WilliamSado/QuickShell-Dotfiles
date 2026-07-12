#!/bin/sh

if command -v pactl >/dev/null 2>&1; then
    pactl_output=$(pactl list sink-inputs 2>/dev/null)
    pactl_status=$?
    if [ "$pactl_status" -eq 0 ]; then
        printf '%s\n' "$pactl_output" | awk '
        function emit() {
            if (id != "") {
                printf "APPACTL\t%s\t%s\t%s\t%s\n", id, volume, muted, name;
            }
        }

        /^Sink Input #/ {
            emit();
            id = substr($3, 2);
            name = "App audio";
            volume = 100;
            muted = "false";
            next;
        }

        /^[[:space:]]*application.name =/ {
            if (match($0, /"[^"]+"/)) {
                name = substr($0, RSTART + 1, RLENGTH - 2);
            }
            next;
        }

        /^[[:space:]]*media.name =/ {
            if (name == "App audio" && match($0, /"[^"]+"/)) {
                name = substr($0, RSTART + 1, RLENGTH - 2);
            }
            next;
        }

        /^[[:space:]]*Mute:/ {
            muted = $2 == "yes" ? "true" : "false";
            next;
        }

        /^[[:space:]]*Volume:/ {
            if (match($0, /\/[[:space:]]*[0-9]+%[[:space:]]*\//)) {
                value = substr($0, RSTART, RLENGTH);
                gsub(/[^0-9]/, "", value);
                if (value != "") volume = value;
            }
            next;
        }

        END { emit(); }
    '
        exit $?
    fi
fi

if command -v wpctl >/dev/null 2>&1; then
    wpctl status
    exit $?
fi

exit 127
