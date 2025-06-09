```py
import requests
from typing import Dict

def search_knowledge_base(query: str) -> Dict:
    """Search the FAQs knowledge base from Zendesk.

    Args:
        query (str): Search query to use.

    Raises:
        requests.exceptions.RequestException: If the API call fails.

    Returns:
        dict: Processed results from zendesk containing article sources.
    """
    try:
        url = "https://nequi.zendesk.com/api/v2/help_center/articles/search"
        headers = {"Content-Type": "application/json"}
        params = {
            "query": query,
            "per_page": 5,
        }
        keep_keys = [
            "id",
            "title",
            "body",
            "html_url",
            "section_id",
            "created_at",
            "updated_at",
        ]

        # Send the GET request - requests automatically handles URL parameter encoding
        response = requests.get(url, params=params, headers=headers)

        # Raise an exception for bad status codes (4xx, 5xx)
        response.raise_for_status()

        # Parse JSON response - requests automatically handles JSON decoding
        raw_response = response.json()
        search_results = raw_response.get("results", [])

        # Process and filter results
        search_results = [
            {k: str(result[k]) for k in keep_keys}
            for result in search_results
            if result.get("body")
        ]
        payload = {"statusCode": "200", "sources": search_results}
        return payload
    except requests.exceptions.RequestException as e:
        # Handle any exceptions that occur during the request
        payload = {"statusCode": "400", "error": str(e)}
        return {"statusCode": "400", "error": str(e)}
    
if __name__ == "__main__":
    # Example usage
    query = "retiro en cajero"
    result = search_knowledge_base(query)
    print(result)
```
