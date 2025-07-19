#!/bin/bash

# Check if log file path is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <log_file_path>"
  exit 1
fi

LOG_FILE="$1"

# Check if the file exists
if [ ! -f "$LOG_FILE" ]; then
  echo "Error: File '$LOG_FILE' does not exist."
  exit 1
fi

# Get analysis timestamp and file size
ANALYZED_ON=$(date "+%Y-%m-%d %H:%M:%S")
FILE_SIZE=$(du -h "$LOG_FILE" | cut -f1)

# Count occurrences of INFO, WARNING, ERROR
INFO_COUNT=$(grep -c "INFO" "$LOG_FILE")
WARNING_COUNT=$(grep -c "WARNING" "$LOG_FILE")
ERROR_COUNT=$(grep -c "ERROR" "$LOG_FILE")

# Extract 5 most common ERROR messages (after the keyword)
TOP_ERRORS=$(grep "ERROR" "$LOG_FILE" | awk -F"ERROR" '{print $2}' | sed 's/^ *//' \
  | sort | uniq -c | sort -nr | head -5)

# Get first and last ERROR timestamps (assumes timestamp at the beginning of the line)
FIRST_ERROR_TS=$(grep "ERROR" "$LOG_FILE" | head -1 | awk '{print $1, $2}')
LAST_ERROR_TS=$(grep "ERROR" "$LOG_FILE" | tail -1 | awk '{print $1, $2}')

# Output Summary
echo "=================== Log Summary Report ==================="
echo "Log File: $LOG_FILE"
echo "Analyzed on    : $ANALYZED_ON"
echo "File size      : $FILE_SIZE"
echo
echo "Total INFO messages   : $INFO_COUNT"
echo "Total WARNING messages: $WARNING_COUNT"
echo "Total ERROR messages  : $ERROR_COUNT"
echo
echo "----- Top 5 Most Common ERROR Messages -----"
echo "$TOP_ERRORS"
echo
echo "----- Error Timeframe -----"
echo "First ERROR at: $FIRST_ERROR_TS"
echo "Last ERROR at : $LAST_ERROR_TS"
echo "=========================================================="
