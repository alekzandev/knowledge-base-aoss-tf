import json
import os
import boto3
import logging
from opensearchpy import OpenSearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_aoss_client():
    """Initialize OpenSearch client for AOSS"""
    region = "us-east-1"  # Change to your AOSS region
    service = 'aoss'
    credentials = boto3.Session().get_credentials()
    awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)
    
    # Get AOSS endpoint
    aoss_endpoint = os.environ.get('AOSS_ENDPOINT')
    if not aoss_endpoint.startswith('https://'):
        endpoint = f"https://{aoss_endpoint}"
    else:
        endpoint = aoss_endpoint
    
    # Extract host from endpoint
    host = endpoint.replace('https://', '').replace('http://', '')
    
    client = OpenSearch(
        hosts=[{'host': host, 'port': 443}],
        http_auth=awsauth,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
        pool_maxsize=20,
    )
    
    return client

def lambda_handler(event, context):
    """
    Lambda handler for querying AOSS collection
    
    Expected event structure:
    {
        "query": "search text",
        "index": "your-index-name",
        "size": 10,
        "query_type": "match" | "multi_match" | "vector" | "custom"
    }
    """
    
    try:
        # Parse request body if coming from API Gateway
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event
            
        # Extract parameters
        query_text = body.get('query', '')
        index_name = body.get('index', 'articles')
        size = body.get('size', 10)
        query_type = body.get('query_type', 'multi_match')
        
        if not query_text:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Query text is required'
                })
            }
        
        # Initialize OpenSearch client
        client = get_aoss_client()
        
        # Build search query based on type
        search_body = build_search_query(query_text, query_type, size, body)
        
        logger.info(f"Executing search on index: {index_name}")
        logger.info(f"Search body: {json.dumps(search_body)}")
        
        # Execute search
        response = client.search(
            index=index_name,
            body=search_body
        )
        
        # Process results
        results = process_search_results(response)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'total_hits': response['hits']['total']['value'],
                'max_score': response['hits']['max_score'],
                'results': results,
                'took': response['took']
            })
        }
        
    except Exception as e:
        logger.error(f"Error executing search: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': f'Search failed: {str(e)}'
            })
        }

def build_search_query(query_text, query_type, size, body):
    """Build OpenSearch query based on type"""
    
    if query_type == "match":
        search_body = {
            "size": size,
            "query": {
                "match": {
                    "body": query_text
                }
            }
        }
    
    elif query_type == "multi_match":
        search_body = {
            "size": size,
            "query": {
                "multi_match": {
                    "query": query_text,
                    "fields": ["title^2", "body"],
                    "type": "best_fields",
                    "fuzziness": "AUTO"
                }
            },
            "highlight": {
                "fields": {
                    "title": {},
                    "body": {
                        "fragment_size": 150,
                        "number_of_fragments": 3
                    }
                }
            }
        }
    
    elif query_type == "vector":
        # For vector search, expect embedding in the request
        vector = body.get('vector')
        if not vector:
            raise ValueError("Vector is required for vector search")
            
        search_body = {
            "size": size,
            "query": {
                "knn": {
                    "embedding": {
                        "vector": vector,
                        "k": size
                    }
                }
            }
        }
    
    elif query_type == "custom":
        # Allow custom query body
        search_body = body.get('custom_query', {})
        if 'size' not in search_body:
            search_body['size'] = size
    
    else:
        # Default to bool query with should clauses
        search_body = {
            "size": size,
            "query": {
                "bool": {
                    "should": [
                        {
                            "match": {
                                "title": {
                                    "query": query_text,
                                    "boost": 2.0
                                }
                            }
                        },
                        {
                            "match": {
                                "body": {
                                    "query": query_text
                                }
                            }
                        }
                    ],
                    "minimum_should_match": 1
                }
            }
        }
    
    return search_body

def process_search_results(response):
    """Process and format search results"""
    results = []
    
    for hit in response['hits']['hits']:
        result = {
            'id': hit['_id'],
            'score': hit['_score'],
            'source': hit['_source']
        }
        
        # Add highlights if available
        if 'highlight' in hit:
            result['highlights'] = hit['highlight']
            
        results.append(result)
    
    return results