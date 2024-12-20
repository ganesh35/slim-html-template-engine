# slim-html-template-engine
This Shell script provides a simple template engine for rendering HTML pages.

## Overview
This Shell script provides a simple template engine for rendering HTML pages. It supports:

- Applying global and page-specific variables to HTML templates.
- Including reusable modules (e.g., header, footer) into templates.
- Rendering multiple HTML files from a directory.

## Script Components

### Variables and Directories
- `TEMPLATE_DIR`: Directory containing the `.html` template files. Default: `pages`.
- `VARIABLES_FILE`: JSON file containing global key-value pairs for template variables. Default: `manifest.json`.
- `MODULES_DIR`: Directory containing reusable module files (e.g., `header.html`). Default: `modules`.
- `OUTPUT_DIR`: Directory where rendered HTML files are saved. Default: `dist`.

### Key Functions

#### 1. Directory and File Checks
The script verifies the existence of essential directories and files:
- `TEMPLATE_DIR`
- `VARIABLES_FILE`
- `MODULES_DIR`

If any required directory or file is missing, the script exits with an error message.

#### 2. `include_modules` Function
Inserts reusable content into templates where placeholders of the form `{{module:<module_name>}}` are found.

**Steps:**
1. Locate placeholders in the template.
2. Replace each placeholder with the content of the corresponding module file from `MODULES_DIR`.
3. Issue a warning if the module file does not exist.

#### 3. Variable Replacement
- The script uses `jq` to parse `VARIABLES_FILE` and page-specific override JSON files.
- Merges global and page-specific variables, applying them to the template.
- Replaces placeholders like `{{key}}` with their corresponding values from the JSON file.

#### 4. Merging JSON Files
- If a page-specific JSON file exists (e.g., `template.json` for `template.html`), it is merged with the global `VARIABLES_FILE` using `jq`.

### Template Processing
- The script processes each `.html` file in `TEMPLATE_DIR`.
- For each template:
  1. Copies the file to `OUTPUT_DIR`.
  2. Replaces placeholders with variable values.
  3. Includes module content.

### Cleanup
- Temporary files (e.g., merged variables JSON) are removed after processing each template.

## Usage
1. Ensure the following directory structure:
   ```
   ├── pages/
   │   ├── index.html
   │   ├── about.html
   ├── modules/
   │   ├── header.html
   │   ├── footer.html
   ├── manifest.json
   ```
2. Run the script:
   ```bash
   ./template_engine.sh
   ```
3. The rendered HTML files will be saved in the `dist/` directory.

## Example
### Template File (`pages/index.html`):
```html
<html>
<head>
    <title>{{title}}</title>
</head>
<body>
    {{module:header}}
    <h1>Welcome, {{username}}!</h1>
    {{module:footer}}
</body>
</html>
```

### Global Variables (`manifest.json`):
```json
{
    "title": "My Website",
    "username": "Alice"
}
```

### Module Files:
#### `modules/header.html`:
```html
<header>
    <h1>Site Header</h1>
</header>
```
#### `modules/footer.html`:
```html
<footer>
    <p>Footer Content</p>
</footer>
```

### Rendered Output (`dist/index.html`):
```html
<html>
<head>
    <title>My Website</title>
</head>
<body>
    <header>
        <h1>Site Header</h1>
    </header>
    <h1>Welcome, Alice!</h1>
    <footer>
        <p>Footer Content</p>
    </footer>
</body>
</html>
```

## Error Handling
- Missing directories or files result in a descriptive error message and script termination.
- Missing modules trigger a warning, leaving the placeholder unchanged.

## Dependencies
- `jq`: A lightweight JSON processor. Ensure it is installed:
  ```bash
  sudo apt-get install jq
  ```

## Customization
- Modify the `TEMPLATE_DIR`, `VARIABLES_FILE`, `MODULES_DIR`, and `OUTPUT_DIR` variables to suit your project.
- Extend the `include_modules` function to support additional module file types if needed.

## Limitations
- Module placeholders must match the exact format `{{module:<module_name>}}`.
- The script processes `.html` files only.

