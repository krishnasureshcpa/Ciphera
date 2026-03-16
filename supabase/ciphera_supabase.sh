#!/usr/bin/env bash
# Ciphera Supabase Integration Module
# Handles database logging and cloud sync

SUPABASE_URL="https://nuxtsotfncxxvtxduytu.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51eHRzb3RmbmN4eHZ0ZHV0dXUiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY0MzU1MjcwMCwiZXhwIjoxOTU5MTI4NzAwfQ.6nN1dE5P__Tqz7aERCT6W_7ShCENTL4R5hub7ch0N_c"
SUPABASEanonKey="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51eHRzb3RmbmN4eHZ0ZHV0dXUiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY0MzU1MjcwMCwiZXhwIjoxOTU5MTI4NzAwfQ.6nN1dE5P__Tqz7aERCT6W_7ShCENTL4R5hub7ch0N_c"

# Colors for output
ESC=$'\e'
GREEN="${ESC}[0;32m"
RED="${ESC}[0;31m"
YELLOW="${ESC}[1;33m"
NC="${ESC}[0m"

supabase_log_extraction() {
    local source="$1"
    local target="$2"
    local total="$3"
    local success="$4"
    local failed="$5"
    local password_used="$6"
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local payload
    payload=$(cat <<EOF
{
    "timestamp": "$timestamp",
    "source_path": "$source",
    "target_path": "$target",
    "total_archives": $total,
    "successful": $success,
    "failed": $failed,
    "password_used": "$password_used",
    "version": "5.0"
}
EOF
)
    
    response=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/extraction_logs" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASEanonKey}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "$payload" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Extraction logged to Supabase${NC}"
    else
        echo -e "${YELLOW}⚠ Supabase logging failed (offline mode)${NC}"
    fi
}

supabase_log_archive() {
    local filename="$1"
    local password="$2"
    local status="$3"
    local size="$4"
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local payload
    payload=$(cat <<EOF
{
    "timestamp": "$timestamp",
    "filename": "$filename",
    "password_used": "$password",
    "status": "$status",
    "file_size": $size
}
EOF
)
    
    curl -s -X POST "${SUPABASE_URL}/rest/v1/archive_logs" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASEanonKey}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=minimal" \
        -d "$payload" >/dev/null 2>&1
}

supabase_check_connection() {
    response=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASEanonKey}" \
        -w "%{http_code}" \
        -o /dev/null 2>&1)
    
    if [ "$response" = "200" ] || [ "$response" = "404" ]; then
        return 0
    else
        return 1
    fi
}

supabase_get_stats() {
    curl -s -X GET "${SUPABASE_URL}/rest/v1/extraction_logs?select=*&order=timestamp.desc&limit=10" \
        -H "apikey: ${SUPABASE_KEY}" \
        -H "Authorization: Bearer ${SUPABASEanonKey}"
}
