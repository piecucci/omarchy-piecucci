#!/bin/bash
ENTE_CLI="${ENTE_CLI:-/tmp/ente}"
EXPORT_DIR="${ENTE_EXPORT_DIR:-$HOME/ente-cli-export}"

CMD="${1:-}"
ACCOUNT_EMAIL=""
ACCOUNT_ARG="${2:-}"

show_accounts() {
    "$ENTE_CLI" account list
}

list_ente_accounts() {
    "$ENTE_CLI" account list | grep "^Email:" | sed 's/.*Email: *//'
}

add_account() {
    "$ENTE_CLI" account add
}

sync_export() {
    local email="$1"
    local dir="$2"
    echo "Syncing $email..."
    ENTE_EXPORT_DIR="$dir" "$ENTE_CLI" export >/dev/null 2>&1
    echo "Done: $dir/ente_auth.txt"
    
    echo "Cleaning up decrypted files..."
    rm -f "$dir"/ente_auth_decrypted.txt
    rm -f "$dir"/ente_auth_*.txt
    echo "Cleanup done"
}

get_account_dir() {
    local email="$1"
    "$ENTE_CLI" account list | grep -A3 "Email:.*$email" | grep "ExportDir:" | sed 's/.*ExportDir: *//'
}

get_all_accounts() {
    "$ENTE_CLI" account list
}

get_account_email() {
    local dir="$1"
    "$ENTE_CLI" account list | grep -B4 "ExportDir:.*$dir" | grep "Email:" | awk '{print $2}'
}

case "$CMD" in
    add)
        add_account
        ;;
    list|ls)
        show_accounts
        ;;
    sync|use)
        ACCOUNT_EMAIL="${2:-}"
        if [ -z "$ACCOUNT_EMAIL" ]; then
            echo "Usage: otp.sh $CMD <email>"
            show_accounts
            exit 1
        fi
        dir=$(get_account_dir "$ACCOUNT_EMAIL")
        if [ -z "$dir" ]; then
            echo "Account not found: $ACCOUNT_EMAIL"
            exit 1
        fi
        if [ "$CMD" = "use" ]; then
            DEFAULT_EMAIL="$ACCOUNT_EMAIL"
            echo "Set default account: $DEFAULT_EMAIL"
        fi
        sync_export "$ACCOUNT_EMAIL" "$dir"
        ;;
    *)
        if [ "$CMD" = "use" ] && [ -n "$ACCOUNT_ARG" ]; then
            email="$ACCOUNT_ARG"
            dir=$(get_account_dir "$email")
            if [ -z "$dir" ]; then
                echo "Account not found: $email"
                exit 1
            fi
            sync_export "$email" "$dir"
            EXPORT_DIR="$dir"
        elif [ -z "$CMD" ]; then
            accounts_raw=$(list_ente_accounts)
            if [ "$(echo "$accounts_raw" | wc -l)" -gt 1 ]; then
                echo "Select ente account:"
                email=$(echo "$accounts_raw" | fzf --height 5 --layout=reverse --border --prompt="Ente Account: ")
                if [ -z "$email" ]; then
                    echo "No account selected."
                    exit 0
                fi
                dir=$(get_account_dir "$email")
                if [ -n "$dir" ]; then
                    sync_export "$email" "$dir"
                    EXPORT_DIR="$dir"
                fi
            else
                email="$accounts_raw"
                dir=$(get_account_dir "$email")
                sync_export "$email" "$dir"
            fi
        elif [ -d "$EXPORT_DIR" ]; then
            sync_export "piecucci@gmail.com" "$EXPORT_DIR"
        fi

        DECRYPTED_FILE="$EXPORT_DIR/ente_auth.txt"

        if [ ! -s "$DECRYPTED_FILE" ]; then
            echo "Error: No auth export found at $DECRYPTED_FILE"
            exit 1
        fi

        if [ "$ACCOUNT_ARG" ]; then
            CHOICE=$(grep -i "$ACCOUNT_ARG" "$DECRYPTED_FILE" | head -1 | sed 's|otpauth://totp/||; s|\?.*||')
            if [ -z "$CHOICE" ]; then
                echo "No account matching: $ACCOUNT_ARG"
                exit 1
            fi
        else
            CHOICE=$(grep "^otpauth://" "$DECRYPTED_FILE" | sed 's|otpauth://totp/||; s|\?.*||' | fzf --height 40% --layout=reverse --border --prompt="Select Account: ")
        fi

        if [ -z "$CHOICE" ]; then
            echo "No account selected."
            exit 0
        fi

        SECRET=$(grep "$CHOICE" "$DECRYPTED_FILE" | head -n 1 | grep -oP 'secret=\K[^&]+')

        if [ -z "$SECRET" ]; then
            echo "Failed to retrieve secret for $CHOICE"
            exit 1
        fi

        echo -n "Code for $CHOICE: "
        oathtool --totp -b "$SECRET"
        ;;
esac