import requests
import json
import re
from bs4 import BeautifulSoup
from typing import List, Dict

def fetch_cda(query: str, pages: int = 1) -> dict:
    """Fetch articles from Zendesk API"""
    url = f"https://nequi.zendesk.com/api/v2/help_center/articles/search?query={query}&per_page={pages}"

    payload = {}
    headers = {
        'Content-Type': 'application/json',
    }

    response = requests.request("GET", url, headers=headers, data=payload)
    zdkskjson = json.loads(response.text)
    return zdkskjson

def fetch_all_articles(per_page: int = 100) -> List[Dict]:
    """Fetch all articles from Zendesk API with pagination"""
    all_articles = []
    page = 1
    
    while True:
        url = f"https://nequi.zendesk.com/api/v2/help_center/articles?per_page={per_page}&page={page}"
        
        headers = {
            'Content-Type': 'application/json',
        }
        
        try:
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            
            data = response.json()
            articles = data.get('articles', [])
            
            if not articles:
                break
                
            all_articles.extend(articles)
            
            # Check if there are more pages
            if not data.get('next_page'):
                break
                
            page += 1
            print(f"Fetched page {page-1}, total articles so far: {len(all_articles)}")
            
        except requests.exceptions.RequestException as e:
            print(f"Error fetching articles: {e}")
            break
    
    return all_articles

def clean_html_content(html_text: str) -> str:
    """
    Clean HTML content while preserving meaningful text structure.
    Completely removes images and cleans up formatting.
    """
    if not html_text:
        return ""
    
    # Parse HTML with BeautifulSoup
    soup = BeautifulSoup(html_text, 'html.parser')
    
    # Remove script and style elements
    for script in soup(["script", "style"]):
        script.decompose()
    
    # Completely remove images
    for img in soup.find_all('img'):
        img.decompose()
    
    # Handle links - preserve text and URL
    for link in soup.find_all('a', href=True):
        link_text = link.get_text().strip()
        link_url = link['href']
        if link_text and link_url:
            link.replace_with(f"{link_text} ({link_url})")
    
    # Extract structured text
    text = _extract_structured_text(soup)
    
    # Clean up whitespace
    text = _clean_whitespace(text)
    
    return text

def _extract_structured_text(soup) -> str:
    """Extract text while preserving basic structure."""
    structured_text = []
    
    for element in soup.find_all(['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'div', 'span']):
        text = element.get_text().strip()
        if text and text not in [t.strip() for t in structured_text]:  # Avoid duplicates
            # Add bullet points for list items
            if element.name == 'li':
                structured_text.append(f"• {text}")
            # Add emphasis for headers
            elif element.name.startswith('h'):
                structured_text.append(f"\n{text}\n")
            else:
                structured_text.append(text)
    
    # If no structured elements found, get all text
    if not structured_text:
        return soup.get_text()
    
    return '\n'.join(structured_text)

def _clean_whitespace(text: str) -> str:
    """Clean up excessive whitespace."""
    # Replace multiple spaces with single space
    text = re.sub(r' +', ' ', text)
    
    # Replace multiple newlines with double newlines max
    text = re.sub(r'\n\s*\n\s*\n+', '\n\n', text)
    
    # Remove leading/trailing whitespace from each line
    lines = [line.strip() for line in text.split('\n')]
    text = '\n'.join(line for line in lines if line)  # Remove empty lines
    
    return text.strip()

def curate_article(article: dict) -> dict:
    """
    Curate article data with only the specified fields.
    
    Fields: id, html_url, updated_at, title, outdated, section_id, body (cleaned)
    """
    return {
        'id': article.get('id'),
        'html_url': article.get('html_url', ''),
        'updated_at': article.get('updated_at', ''),
        'title': article.get('title', ''),
        'created_at': article.get('created_at', ''),
        'section_id': article.get('section_id'),
        'body': clean_html_content(article.get('body', ''))
    }

def save_to_ndjson(articles: List[Dict], filename: str = 'curated_articles.ndjson') -> None:
    """
    Save curated articles to NDJSON file.
    Each line contains one JSON object.
    """
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            for article in articles:
                #wrapped_article = {"results": article}
                json_line = json.dumps(article, ensure_ascii=False)
                f.write(json_line + '\n')
        
        print(f"Successfully saved {len(articles)} articles to {filename}")
        
    except Exception as e:
        print(f"Error saving to NDJSON: {e}")

def load_from_ndjson(filename: str) -> List[Dict]:
    """Load articles from NDJSON file."""
    articles = []
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            for line in f:
                if line.strip():
                    data = json.loads(line)
                    if "results" in data:
                        articles.append(data["results"])
                    else:
                        # Handle old format without wrapper
                        articles.append(data)
        print(f"Loaded {len(articles)} articles from {filename}")
        return articles
    except Exception as e:
        print(f"Error loading from NDJSON: {e}")
        return []

def main():
    """Main function to process all articles and save to NDJSON."""
    print("Starting article curation process...")
    
    # Option 1: Fetch all articles (recommended for complete dataset)
    print("Fetching all articles...")
    all_articles = fetch_all_articles()
    
    if not all_articles:
        print("No articles found. Exiting.")
        return
    
    print(f"Found {len(all_articles)} articles. Processing...")
    
    # Curate articles
    curated_articles = []
    for i, article in enumerate(all_articles):
        try:
            curated_article = curate_article(article)
            curated_articles.append(curated_article)
            
            if (i + 1) % 50 == 0:
                print(f"Processed {i + 1}/{len(all_articles)} articles")
                
        except Exception as e:
            print(f"Error processing article {article.get('id', 'unknown')}: {e}")
            continue
    
    # Save to NDJSON
    output_filename = 'curated_zendesk_articles.ndjson'
    save_to_ndjson(curated_articles, output_filename)
    
    # Display sample
    if curated_articles:
        print(f"\nSample curated article:")
        sample = curated_articles[0]
        for key, value in sample.items():
            if key == 'body':
                print(f"{key}: {str(value)[:200]}..." if len(str(value)) > 200 else f"{key}: {value}")
            else:
                print(f"{key}: {value}")

def search_and_curate(query: str, max_pages: int = 10):
    """Alternative function to search and curate specific articles."""
    print(f"Searching for articles with query: '{query}'")
    
    search_results = fetch_cda(query, max_pages)
    articles = search_results.get('results', [])
    
    if not articles:
        print("No articles found for the query.")
        return
    
    print(f"Found {len(articles)} articles. Processing...")
    
    curated_articles = []
    for article in articles:
        try:
            curated_article = curate_article(article)
            curated_articles.append(curated_article)
        except Exception as e:
            print(f"Error processing article {article.get('id', 'unknown')}: {e}")
            continue
    
    # Save to NDJSON
    filename = f'search_results_{query.replace(" ", "_")}.ndjson'
    save_to_ndjson(curated_articles, filename)
    
    return curated_articles

if __name__ == "__main__":
    # Option 1: Process all articles
    main()
    
    # Option 2: Search specific query (uncomment to use)
    # search_and_curate("paypal nequi", max_pages=5)