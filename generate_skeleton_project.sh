#!/bin/bash
DEBUG=false

# Function for debug logging
debug_log() {
  if $DEBUG; then
    echo "$1"
  fi
}
# Parse command-line arguments
if [[ $1 == "--debug" ]]; then DEBUG=true; fi

# Create necessary folders
debug_log "==> Creating folders - pages,modules,assets,assets/css,assets/img,assets/js"
mkdir -p {pages,modules,assets,assets/css,assets/img,assets/js}
debug_log "==> Creating folders - Done"

# Create the manifest.json file
debug_log "==> Creating manifest.json"
cat <<EOL > manifest.json
{
  "name": "slim-html-template-engine",
  "version": "0.0.1-SNAPSHOT",  
  "logo_text": "HTML Template Engine",
  "header": "Template Engine for HTML pages",  
  "default_description": "A simple template engine for rendering HTML pages using jq and shell scripts",
  "menu_items": [
    {
      "text": "Home",
      "link": "index.html"
    },
    {
      "text": "About",
      "link": "about.html"
    },
    {
      "text": "Contact",
      "link": "contact.html"
    }
  ]  
}
EOL
debug_log "==> Creating manifest.json - Done"

# Create basic styles.css file
debug_log "==> Creating styles.css"
cat <<EOL > assets/css/styles.css
body {font-family: "Courier New", Courier, monospace;background-color: #f6f8fa;margin: 0;padding: 0;color: #24292e;}header {background-color: #24292e;color: #ffffff;padding: 1rem;text-align: center;}header .logo {font-size: 1.8rem;font-weight: bold;}nav {background-color: #e1e4e8;padding: 0.5rem 1rem;display: flex;justify-content: center;}nav a {font-family: "Courier New", Courier, monospace;margin: 0 1rem;text-decoration: none;color: #079196;font-weight: bold;}nav a:hover {text-decoration: underline;}.content {max-width: 800px;margin: 2rem auto;padding: 1rem;}.content h1, .content h2, .content p {margin-bottom: 1rem;}h1, h2 {color: #079196;}footer {text-align: center;padding: 1rem;background-color: #e1e4e8;margin-top: 2rem;}.active-link {color: #035457;text-decoration: underline;}
EOL
debug_log "==> Creating styles.css - Done"


# Creating basic modules (header,footer,mainmenu)
debug_log "==> Creating basic modules (header,footer,mainmenu)"

# Creating header footer
cat <<EOL > modules/header.html
<head>  
  <title>{{header}} - {{description}}</title>
  <link rel="stylesheet" href="assets/css/styles.css">
</head>
EOL

# Creating header footer
cat << 'EOL' > modules/mainmenu.sh
current_page=$(jq -r '.current_page' merged_variables.json)
menu_items=$(jq -r '.menu_items[] | {link, text}' manifest.json)
html_output=""
while IFS= read -r item; do
    link=$(echo "$item" | jq -r '.link')
    text=$(echo "$item" | jq -r '.text')
    class=$(if [[ "$link" == "$current_page" ]]; then echo "active-link"; else echo ""; fi)
    html_output+="<a href=\"$link\" class=\"$class\">$text</a>\n"
done <<< "$(jq -c '.menu_items[]' manifest.json)"
echo "<header><div class=\"logo\">{{logo_text}}</div></header><nav>${html_output}</nav>"
EOL

# Creating module footer
year=$(date +%Y)
cat <<EOL > modules/footer.html
<footer>
  &copy; ${year} {{name}}. All Rights Reserved.</span>
</footer>
EOL
debug_log "==> Creating basic modules - Done"

# Creating sample pages
debug_log "==> Creating sample pages"

## Create index.html
cat <<EOL > pages/index.html
<!DOCTYPE html>
<html lang="en">  
  {{module:header}}
<body> 
  {{module:mainmenu}}
  <div class="content">
    <h1>What is {{name}}</h1>
    <p>This Shell script provides a simple template engine for rendering HTML pages. It supports:</p>
    <p>- Applying global and page-specific variables to HTML templates.</p>
    <p>- Including reusable modules (e.g., header, footer) into templates.</p>
    <p>- Rendering multiple HTML files from a directory.</p>    
  </div> 
  {{module:footer}}
</body>
</html>
EOL

## Create index.json
cat <<EOL > pages/index.json
{
  "header": "Work only on html",
  "description": "Generate html pages on the fly"  
}
EOL

## Create about.html
cat <<EOL > pages/about.html
<!DOCTYPE html>
<html lang="en">  
  {{module:header}}
<body> 
  {{module:mainmenu}}
  <div class="content">
    <h1>About {{name}}</h1>
    <p>Goal of this script to simplify the process of creating beautiful and functional websites. We provide an easy-to-use platform that allows users to generate HTML code quickly and efficiently, without needing extensive coding knowledge.</p>
  </div> 
  {{module:footer}}
</body>
</html>
EOL

## Create about.json
cat <<EOL > pages/about.json
{
  "header": "About",
  "description": "Generate html pages"  
}
EOL

## Create contact.html
cat <<EOL > pages/contact.html
<!DOCTYPE html>
<html lang="en">  
  {{module:header}}
<body> 
  {{module:mainmenu}}
  <div class="content">
    <h1>Contact {{name}}</h1>
    <p>We value your feedback and are here to assist you with any questions or concerns. Whether you have a question about our platform, need technical support, or want to discuss partnership opportunities, we're ready to help.</p>
  </div> 
  {{module:footer}}
</body>
</html>
EOL

## Create about.json
cat <<EOL > pages/contact.json
{
  "header": "Contact",
  "description": "A Generic contact page"  
}
EOL

debug_log "==> Creating sample pages - Done"

echo "Skeleton project generated successfully!"


