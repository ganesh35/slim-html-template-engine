#!/bin/bash

# A simple shell script template engine for HTML pages

TEMPLATE_DIR="pages"
VARIABLES_FILE="manifest.json"
MODULES_DIR="modules"
ASSETS_DIR="assets"
OUTPUT_DIR="dist"
BUILD_DIR="$OUTPUT_DIR/build"
INFO_FILE="info.json"
MENU_ITEMS_FILE="$OUTPUT_DIR/menu_items.json"
DEBUG=false

# Function for debug logging
debug_log() {
  if $DEBUG; then
    echo "$1"
  fi
}

# Parse command-line arguments
if [[ $1 == "--debug" ]]; then DEBUG=true; fi

# Check if directories and files exist
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Error: Template directory '$TEMPLATE_DIR' not found."
  exit 1
fi

if [ ! -f "$VARIABLES_FILE" ]; then
  echo "Error: Variables file '$VARIABLES_FILE' not found."
  exit 1
fi

if [ ! -d "$MODULES_DIR" ]; then
  echo "Error: Modules directory '$MODULES_DIR' not found."
  exit 1
fi

# Remove and recreate output directory
if [ -d "$OUTPUT_DIR" ]; then
  debug_log "Removing existing output directory '$OUTPUT_DIR'"
  rm -rf "$OUTPUT_DIR"
fi
mkdir -p "$BUILD_DIR"

# Copy assets to output directory
copy_assets() {
  if [ -d "$ASSETS_DIR" ]; then
    debug_log "Copying assets from $ASSETS_DIR to $OUTPUT_DIR"
    cp -r "$ASSETS_DIR" "$OUTPUT_DIR"
    debug_log "Assets copied successfully."
  else
    debug_log "Assets directory '$ASSETS_DIR' not found. Skipping asset copying."
  fi
}

# Function to include modules into the template
include_modules() {
  local file=$1

  # Find and replace all module placeholders in the file
  while grep -qE "{{module:([a-zA-Z0-9_-]+)}}" "$file"; do
    # Extract the module placeholders
    placeholders=$(sed -n 's/{{module:\([^}]*\)}}/\1/p' "$file")
    #debug_log "Found placeholders: $placeholders"

    for placeholder in $placeholders; do
      # Extract the module name
      module_file_html="$MODULES_DIR/$placeholder.html"
      module_file_script="$MODULES_DIR/$placeholder.sh"
      module_placeholder="{{module:$placeholder}}"
      module_content=""

      if [ -f "$module_file_html" ]; then
        debug_log "Processing HTML module: $module_file_html"
        # Read the module content
        module_content=$(cat "$module_file_html")
      elif [ -f "$module_file_script" ]; then
        debug_log "Processing executable module: $module_file_script"
        # Execute the script and capture its output
        module_content=$(bash "$module_file_script")
      else
        echo "Warning: Module file '$module_file_html' or script '$module_file_script' not found. Placeholder '$placeholder' left unchanged."
      fi

      # Escape special characters in the content for sed
      module_content=$(printf '%s' "$module_content" | sed 's/[&/]/\\&/g')
      module_content=$(printf '%s' "$module_content" | sed ':a;N;$!ba;s/\n//g;s/  */ /g;s/[\t]*//g')

      # Replace the placeholder with the module content        
      debug_log "Replacing $module_placeholder with content from $module_file_html"
      sed -i "s/$module_placeholder/$module_content/g" "$file"

    done
  done
}

# Function to process templates in a single directory
process_templates() {
  for entry in "$TEMPLATE_DIR"/*.html; do
    
    if [ -f "$entry" ]; then
      output_file="$OUTPUT_DIR/$(basename "$entry")"
      
      cp "$entry" "$output_file"

      # Check if a page-specific JSON override exists
      page_override_file="${entry%.html}.json"

      # Merge global and page-specific variables
      if [ -f "$page_override_file" ]; then
        jq -s 'reduce .[] as $item ({}; . * $item)' "$VARIABLES_FILE" "$page_override_file" > merged_variables.json
      else
        cp "$VARIABLES_FILE" merged_variables.json
      fi

      page=$(basename "$entry")
      debug_log "----------------------------------"
      debug_log "--- working with $page"
      jq --arg v "$page" '.current_page = $v' merged_variables.json > temp.json
      rm -rf merged_variables.json; mv temp.json merged_variables.json

      # Include modules into the output file
      include_modules "$output_file"

      # Apply variables to the template
      jq -r 'to_entries | .[] | "\(.key)=\(.value)"' merged_variables.json | while IFS='=' read -r key value; do
        # Strip surrounding whitespace from key and value
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        # Escape special characters in the value for sed
        value=$(printf '%s' "$value" | sed 's/[&/]/\\&/g')

        # Replace placeholders in the output file
        debug_log "Replacing {{$key}} with $value in $output_file"
        sed -i "s/{{$key}}/$value/g" "$output_file"
      done

      # Clean up temporary merged variables file
      rm -f merged_variables.json
    fi
  done
}

# Function to create an info JSON file
create_info_file() {
  debug_log "Creating info JSON file in $BUILD_DIR"
  version=$(jq -r '.version // "unknown"' "$VARIABLES_FILE")
  name=$(jq -r '.name // "unknown"' "$VARIABLES_FILE")
  commit_id=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

  printf '{
    "status": "%s",
    "name": "%s",
    "version": "%s",
    "commit_id": "%s"
  }\n' \
  "OK" \
  "${name}" \
  "${version}" \
  "${commit_id}" > "$BUILD_DIR/$INFO_FILE"
  #echo '{"status":"OK","name":"$name'","version":"'$version'","build":"'$build'","commit_id":"'$commit_id'"}' > "$BUILD_DIR/$INFO_FILE"  
  debug_log "Info JSON file created: $BUILD_DIR/$INFO_FILE"
}

# Function to create menu_items.json
create_menu_items_file() {
  debug_log "Creating menu_items.json in $OUTPUT_DIR"
  jq -r '.menu_items // []' "$VARIABLES_FILE" > "$MENU_ITEMS_FILE"
  debug_log "menu_items.json file created: $MENU_ITEMS_FILE"
}

# Start processing templates in a single directory
process_templates

# Copy assets to output directory
copy_assets

# Create info JSON file
create_info_file

# Create menu_items.json
create_menu_items_file

echo "Generated HTML files saved to '$OUTPUT_DIR'."
