
import requests
import json
import re
from bs4 import BeautifulSoup

def fetch_cda(query: str, pages: int = 1) -> dict:
    url = f"https://nequi.zendesk.com/api/v2/help_center/articles/search?query={query}&per_page={pages}"

    payload = {}
    headers = {
    'Content-Type': 'application/json',
    }

    response = requests.request("GET", url, headers=headers, data=payload)
    zdkskjson = json.loads(response.text)
    return zdkskjson

def clean_html_content(html_text: str, preserve_links: bool = True, preserve_structure: bool = True, remove_images: bool = True) -> str:
    """
    Clean HTML content while preserving meaningful text and structure.
    
    Args:
        html_text: Raw HTML content to clean
        preserve_links: Whether to preserve link URLs in parentheses
        preserve_structure: Whether to preserve basic text structure (paragraphs, lists)
        remove_images: Whether to completely remove images or keep simple placeholders
    
    Returns:
        Cleaned text content
    """
    if not html_text:
        return ""
    
    # Parse HTML with BeautifulSoup
    soup = BeautifulSoup(html_text, 'html.parser')
    
    # Remove script and style elements
    for script in soup(["script", "style"]):
        script.decompose()
    
    # Handle links if we want to preserve them
    if preserve_links:
        for link in soup.find_all('a', href=True):
            link_text = link.get_text().strip()
            link_url = link['href']
            if link_text and link_url:
                # Replace link with text + URL in parentheses
                link.replace_with(f"{link_text} ({link_url})")
    
    # Handle images - completely remove them or keep minimal placeholder
    for img in soup.find_all('img'):
        if remove_images:
            # Completely remove images without any trace
            img.decompose()
        else:
            # Keep only alt text if available, otherwise remove
            alt_text = img.get('alt', '').strip()
            if alt_text:
                img.replace_with(f"[Image: {alt_text}]")
            else:
                img.decompose()
    
    # Get text content
    if preserve_structure:
        # Preserve paragraph breaks and list structure
        text = _extract_structured_text(soup)
    else:
        # Simple text extraction
        text = soup.get_text()
    
    # Clean up whitespace
    text = _clean_whitespace(text)
    
    return text

def _extract_structured_text(soup) -> str:
    """Extract text while preserving basic structure."""
    structured_text = []
    
    for element in soup.find_all(['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'div']):
        text = element.get_text().strip()
        if text:
            # Add bullet points for list items
            if element.name == 'li':
                structured_text.append(f"• {text}")
            # Add emphasis for headers
            elif element.name.startswith('h'):
                structured_text.append(f"\n{text.upper()}\n")
            else:
                structured_text.append(text)
    
    # If no structured elements found, get all text
    if not structured_text:
        return soup.get_text()
    
    return '\n\n'.join(structured_text)

def _clean_whitespace(text: str) -> str:
    """Clean up excessive whitespace."""
    # Replace multiple spaces with single space
    text = re.sub(r' +', ' ', text)
    
    # Replace multiple newlines with double newlines
    text = re.sub(r'\n\s*\n\s*\n+', '\n\n', text)
    
    # Remove leading/trailing whitespace from each line
    lines = [line.strip() for line in text.split('\n')]
    text = '\n'.join(lines)
    
    return text.strip()

def clean_html_simple(html_text: str) -> str:
    """
    Simple HTML cleaning - just remove all tags and clean whitespace.
    """
    if not html_text:
        return ""
    
    # Remove HTML tags using regex
    text = re.sub(r'<[^>]+>', '', html_text)
    
    # Decode HTML entities
    from html import unescape
    text = unescape(text)
    
    # Clean whitespace
    text = _clean_whitespace(text)
    
    return text

# Integration with your ETL script
def clean_article_body(body: str) -> str:
    """
    Specific function to clean article body content for your use case.
    Removes all images and their sources completely.
    """
    return clean_html_content(
        body, 
        preserve_links=True, 
        preserve_structure=True,
        remove_images=True  # This will completely remove all images
    )

def process_article(article: dict) -> dict:
    """Process and clean article data."""
    return {
        'title': article.get('title', ''),
        'url': article.get('html_url', ''),
        'updated_at': article.get('updated_at', ''),
        'outdated': article.get('outdated', False),
        'labels': article.get('label_names', []),
        'body': clean_article_body(article.get('body', '')),
        'raw_body': article.get('body', ''),  # Keep original for reference
    }

if __name__ == "__main__":
    query = "puedo tener paypal en nequi?"
    zdkskjson = fetch_cda(query)
    results = zdkskjson["results"]
    
    if results:
        article = results[0]
        processed_article = process_article(article)
        
        print(f"Title: {processed_article['title']}")
        print(f"URL: {processed_article['url']}")
        print(f"Updated at: {processed_article['updated_at']}")
        print(f"Outdated: {processed_article['outdated']}")
        print(f"Labels: {', '.join(processed_article['labels'])}")
        print(f"\nCleaned Body:\n{processed_article['body']}")
        print(f"\n{'='*50}")
        print(f"Raw Body:\n{processed_article['raw_body'][:200]}...")
    else:
        print("No articles found for the query.")