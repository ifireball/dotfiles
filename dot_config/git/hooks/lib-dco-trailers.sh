# Shared DCO sign-off helpers for global Git hooks.
# Ensures exactly one Signed-off-by (from user.name / user.email) appears
# immediately before other commit message trailers (Co-authored-by, Assisted-by, …).

dco_signoff_line() {
	name=$(git config --get user.name) || return 1
	email=$(git config --get user.email) || return 1
	printf 'Signed-off-by: %s <%s>' "$name" "$email"
}

# Rewrite $1 in place: body, then Signed-off-by, then other trailers.
dco_fixup_message() {
	msgfile=$1
	sob=$(dco_signoff_line) || {
		echo "dco: set user.name and user.email for DCO sign-off" >&2
		return 1
	}

	tmp=$(mktemp "${msgfile}.XXXXXX") || return 1
	# shellcheck disable=SC2064
	trap 'rm -f "$tmp"' EXIT HUP INT TERM

	# shellcheck disable=SC2016
	awk -v sob="$sob" '
		function is_trailer(line) {
			return line ~ /^[A-Za-z][A-Za-z0-9-]*(-[A-Za-z0-9-]+)*: /
		}
		{
			lines[++n] = $0
		}
		END {
			if (n == 0) {
				print sob
				exit
			}
			last = n
			trailer_count = 0
			i = n
			while (i >= 1) {
				if (is_trailer(lines[i])) {
					trailer_count++
					i--
				} else if (lines[i] == "" && trailer_count > 0) {
					i--
				} else {
					break
				}
			}
			body_end = i
			tstart = i + 1
			while (tstart <= last && lines[tstart] == "") {
				tstart++
			}
			ot = 0
			for (j = tstart; j <= last; j++) {
				if (lines[j] == "") {
					continue
				}
				if (lines[j] ~ /^Signed-off-by: /) {
					continue
				}
				other[++ot] = lines[j]
			}
			for (j = 1; j <= body_end; j++) {
				print lines[j]
			}
			need_sep = (body_end > 0 && (body_end > 1 || lines[1] != ""))
			if (need_sep) {
				print ""
			}
			print sob
			for (j = 1; j <= ot; j++) {
				print other[j]
			}
		}
	' "$msgfile" >"$tmp" || return 1
	mv "$tmp" "$msgfile"
	trap - EXIT HUP INT TERM
	return 0
}

dco_message_has_signoff() {
	msgfile=$1
	grep -q '^Signed-off-by: ' "$msgfile"
}
