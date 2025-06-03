"""
AI Chatbot Lambda Function with OpenSearch Serverless Vector Database
Optimized for near real-time similarity search and AI model inference
"""

import json
import os
import boto3
import logging
from typing import Dict, List, Any
from datetime import datetime
import uuid
import time

try:
    from opensearchpy import OpenSearch, RequestsHttpConnection
    from aws_requests_auth.aws_auth import AWSRequestsAuth
except ImportError:
    OpenSearch = None
    RequestsHttpConnection = None
    AWSRequestsAuth = None

# Configure logging
logging.basicConfig(level=getattr(logging, os.getenv('LOG_LEVEL', 'INFO')))
logger = logging.getLogger(__name__)

# Initialize AWS clients
bedrock = boto3.client('bedrock-runtime', region_name=os.getenv('AWS_DEFAULT_REGION', 'us-east-1'))
cloudwatch = boto3.client('cloudwatch')

# OpenSearch Configuration
OPENSEARCH_ENDPOINT = os.getenv('OPENSEARCH_ENDPOINT')
OPENSEARCH_COLLECTION_NAME = os.getenv('OPENSEARCH_COLLECTION_NAME')
OPENSEARCH_INDEX_NAME = os.getenv('OPENSEARCH_INDEX_NAME', 'knowledge-base')
OPENSEARCH_VECTOR_FIELD = os.getenv('OPENSEARCH_VECTOR_FIELD', 'vector_field')
OPENSEARCH_VECTOR_DIMENSION = int(os.getenv('OPENSEARCH_VECTOR_DIMENSION', '1536'))

# AI Model Configuration
EMBEDDING_MODEL_ID = os.getenv('BEDROCK_EMBEDDING_MODEL_ID', 'amazon.titan-embed-text-v1')
TEXT_MODEL_ID = os.getenv('BEDROCK_TEXT_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')
MAX_TOKENS = int(os.getenv('BEDROCK_MAX_TOKENS', '4000'))
TEMPERATURE = float(os.getenv('BEDROCK_TEMPERATURE', '0.1'))

# Vector Search Configuration
SIMILARITY_THRESHOLD = float(os.getenv('VECTOR_SIMILARITY_THRESHOLD', '0.8'))
MAX_SEARCH_RESULTS = int(os.getenv('VECTOR_MAX_RESULTS', '10'))
SEARCH_TIMEOUT = int(os.getenv('VECTOR_SEARCH_TIMEOUT', '30'))

# Knowledge Base Configuration
CHUNK_SIZE = int(os.getenv('KB_CHUNK_SIZE', '1000'))
MIN_RELEVANCE_SCORE = float(os.getenv('KB_MIN_RELEVANCE_SCORE', '0.7'))

# S3 Configuration (optional backup)
S3_BUCKET_NAME = os.getenv('S3_BUCKET_NAME')

# Performance Monitoring
ENABLE_PERFORMANCE_METRICS = os.getenv('ENABLE_PERFORMANCE_METRICS', 'true').lower() == 'true'

# Initialize OpenSearch client
opensearch_client = None


def get_opensearch_client() -> OpenSearch:
    """Initialize and return OpenSearch client with AWS authentication"""
    global opensearch_client
    
    if opensearch_client is None:
        if not OpenSearch:
            raise ImportError("opensearch-py library not installed. Run: pip install opensearch-py aws-requests-auth")
        
        if not OPENSEARCH_ENDPOINT:
            raise ValueError("OPENSEARCH_ENDPOINT environment variable is required")
        
        # Extract host from endpoint URL
        host = OPENSEARCH_ENDPOINT.replace('https://', '').replace('http://', '')
        region = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
        
        # Get AWS credentials
        credentials = boto3.Session().get_credentials()
        awsauth = AWSRequestsAuth(credentials, region, 'aoss')
        
        opensearch_client = OpenSearch(
            hosts=[{'host': host, 'port': 443}],
            http_auth=awsauth,
            use_ssl=True,
            verify_certs=True,
            connection_class=RequestsHttpConnection,
            pool_maxsize=20,
            timeout=SEARCH_TIMEOUT
        )
        
        logger.info(f"Initialized OpenSearch client for {host}")
    
    return opensearch_client


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for AI chatbot requests with OpenSearch vector search
    """
    start_time = time.time()
    
    try:
        logger.info(f"Processing AI chatbot request: {json.dumps(event, default=str)}")
        
        # Extract user query from event
        user_query = event.get('query', '')
        conversation_id = event.get('conversation_id', str(uuid.uuid4()))
        user_id = event.get('user_id', 'anonymous')
        
        if not user_query:
            raise ValueError("No query provided in the request")
        
        # Process the AI request with vector search
        response_data = process_ai_request_with_vector_search(
            user_query=user_query,
            conversation_id=conversation_id,
            user_id=user_id,
            context=context
        )
        
        # Record performance metrics
        if ENABLE_PERFORMANCE_METRICS:
            record_performance_metrics(start_time, 'success')
        
        logger.info("Generated AI response successfully")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'X-Request-ID': context.aws_request_id if context else str(uuid.uuid4()),
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response_data)
        }
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}", exc_info=True)
        
        # Record performance metrics for failures
        if ENABLE_PERFORMANCE_METRICS:
            record_performance_metrics(start_time, 'error')
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e),
                'request_id': context.aws_request_id if context else str(uuid.uuid4())
            })
        }


def process_ai_request_with_vector_search(
    user_query: str, 
    conversation_id: str, 
    user_id: str, 
    context: Any
) -> Dict[str, Any]:
    """Process the AI request through the complete OpenSearch pipeline"""
    
    # Generate query embedding
    query_embedding = generate_embedding(user_query)
    
    # Search OpenSearch for relevant context
    relevant_context = search_opensearch_vectors(query_embedding)
    
    # Generate response using Bedrock with context
    ai_response = generate_bedrock_response(user_query, relevant_context)
    
    # Store interaction (optional backup to S3)
    interaction_id = store_interaction(user_query, ai_response, conversation_id, user_id)
    
    return {
        'answer': ai_response,
        'context_sources': relevant_context.get('sources', []),
        'interaction_id': interaction_id,
        'conversation_id': conversation_id,
        'timestamp': datetime.utcnow().isoformat(),
        'model_id': TEXT_MODEL_ID,
        'similarity_threshold': SIMILARITY_THRESHOLD,
        'chunk_count': relevant_context.get('chunk_count', 0)
    }


def generate_embedding(text: str) -> List[float]:
    """Generate vector embedding for text using Amazon Bedrock"""
    try:
        response = bedrock.invoke_model(
            modelId=EMBEDDING_MODEL_ID,
            body=json.dumps({"inputText": text})
        )
        
        response_body = json.loads(response['body'].read())
        embedding = response_body['embedding']
        
        logger.info(f"Generated embedding with dimension: {len(embedding)}")
        return embedding
        
    except Exception as e:
        logger.error(f"Error generating embedding: {str(e)}")
        # Return zero vector as fallback
        return [0.0] * OPENSEARCH_VECTOR_DIMENSION


def search_opensearch_vectors(query_embedding: List[float]) -> Dict[str, Any]:
    """Search OpenSearch Serverless for relevant context using vector similarity"""
    try:
        client = get_opensearch_client()
        
        # Construct k-NN search query
        search_body = {
            "size": MAX_SEARCH_RESULTS,
            "query": {
                "knn": {
                    OPENSEARCH_VECTOR_FIELD: {
                        "vector": query_embedding,
                        "k": MAX_SEARCH_RESULTS
                    }
                }
            },
            "_source": ["content", "title", "metadata", "timestamp"],
            "min_score": MIN_RELEVANCE_SCORE
        }
        
        # Execute search
        response = client.search(
            index=OPENSEARCH_INDEX_NAME,
            body=search_body
        )
        
        sources = []
        context_chunks = []
        
        for hit in response['hits']['hits']:
            score = hit['_score']
            source_data = hit['_source']
            
            if score >= MIN_RELEVANCE_SCORE:
                sources.append({
                    'id': hit['_id'],
                    'score': score,
                    'title': source_data.get('title', 'Unknown'),
                    'metadata': source_data.get('metadata', {})
                })
                
                content = source_data.get('content', '')
                if content:
                    context_chunks.append(content)
        
        logger.info(f"Found {len(context_chunks)} relevant chunks from OpenSearch")
        
        return {
            'context': '\n\n'.join(context_chunks),
            'sources': sources,
            'chunk_count': len(context_chunks),
            'total_hits': response['hits']['total']['value']
        }
        
    except Exception as e:
        logger.error(f"Error searching OpenSearch vectors: {str(e)}")
        return {
            'context': '', 
            'sources': [], 
            'chunk_count': 0,
            'total_hits': 0,
            'error': str(e)
        }


def generate_bedrock_response(user_query: str, context_info: Dict[str, Any]) -> str:
    """Generate AI response using Amazon Bedrock with retrieved context"""
    try:
        # Construct enhanced prompt with context
        context_text = context_info.get('context', '')
        source_count = context_info.get('chunk_count', 0)
        
        if context_text:
            prompt = f"""You are a helpful AI assistant. Answer the user's question using the provided context information. If the context doesn't contain enough information to fully answer the question, say so and provide what information you can.

Context Information ({source_count} relevant sources):
{context_text}

User Question: {user_query}

Please provide a comprehensive and accurate answer based on the context provided."""
        else:
            prompt = f"""You are a helpful AI assistant. The user has asked a question, but no relevant context was found in the knowledge base. Please provide a helpful response acknowledging this limitation.

User Question: {user_query}

Please provide a helpful response."""
        
        # Call Bedrock based on model type
        if 'claude' in TEXT_MODEL_ID.lower():
            # Claude model format
            response = bedrock.invoke_model(
                modelId=TEXT_MODEL_ID,
                body=json.dumps({
                    "prompt": f"\n\nHuman: {prompt}\n\nAssistant:",
                    "max_tokens_to_sample": MAX_TOKENS,
                    "temperature": TEMPERATURE,
                    "top_p": 1,
                    "stop_sequences": ["\n\nHuman:"]
                })
            )
        else:
            # Generic model format
            response = bedrock.invoke_model(
                modelId=TEXT_MODEL_ID,
                body=json.dumps({
                    "prompt": prompt,
                    "maxTokens": MAX_TOKENS,
                    "temperature": TEMPERATURE,
                    "topP": 1
                })
            )
        
        response_body = json.loads(response['body'].read())
        
        # Extract response based on model format
        if 'completion' in response_body:
            answer = response_body['completion'].strip()
        elif 'completions' in response_body:
            answer = response_body['completions'][0].get('text', '').strip()
        elif 'text' in response_body:
            answer = response_body['text'].strip()
        else:
            answer = str(response_body)
        
        logger.info(f"Generated Bedrock response with {len(answer)} characters")
        return answer
        
    except Exception as e:
        logger.error(f"Error generating Bedrock response: {str(e)}")
        return "I'm sorry, I'm experiencing technical difficulties and cannot provide an answer at the moment. Please try again later."


def store_interaction(
    user_query: str, 
    ai_response: str, 
    conversation_id: str, 
    user_id: str
) -> str:
    """Store the interaction optionally in S3 for backup and analytics"""
    interaction_id = str(uuid.uuid4())
    
    if not S3_BUCKET_NAME:
        logger.info("S3 bucket not configured, skipping interaction storage")
        return interaction_id
    
    try:
        s3 = boto3.client('s3')
        timestamp = datetime.utcnow().isoformat()
        
        interaction_data = {
            'id': interaction_id,
            'conversation_id': conversation_id,
            'user_id': user_id,
            'query': user_query,
            'response': ai_response,
            'timestamp': timestamp,
            'model_id': TEXT_MODEL_ID,
            'embedding_model_id': EMBEDDING_MODEL_ID
        }
        
        # Store the interaction
        s3.put_object(
            Bucket=S3_BUCKET_NAME,
            Key=f"interactions/{datetime.utcnow().strftime('%Y/%m/%d')}/{interaction_id}.json",
            Body=json.dumps(interaction_data, indent=2),
            ContentType='application/json'
        )
        
        logger.info(f"Stored interaction: {interaction_id}")
        
    except Exception as e:
        logger.error(f"Error storing interaction: {str(e)}")
    
    return interaction_id


def record_performance_metrics(start_time: float, status: str) -> None:
    """Record performance metrics to CloudWatch"""
    try:
        duration = time.time() - start_time
        
        cloudwatch.put_metric_data(
            Namespace='AI-Chatbot/Lambda',
            MetricData=[
                {
                    'MetricName': 'RequestDuration',
                    'Value': duration * 1000,  # Convert to milliseconds
                    'Unit': 'Milliseconds',
                    'Dimensions': [
                        {
                            'Name': 'Status',
                            'Value': status
                        }
                    ]
                },
                {
                    'MetricName': 'RequestCount',
                    'Value': 1,
                    'Unit': 'Count',
                    'Dimensions': [
                        {
                            'Name': 'Status',
                            'Value': status
                        }
                    ]
                }
            ]
        )
        
        logger.info(f"Recorded performance metrics: {duration:.2f}s, status: {status}")
        
    except Exception as e:
        logger.error(f"Error recording performance metrics: {str(e)}")


def health_check() -> Dict[str, Any]:
    """Health check function for monitoring"""
    try:
        # Test OpenSearch connection
        client = get_opensearch_client()
        cluster_health = client.cluster.health()
        
        # Test Bedrock connection
        bedrock.list_foundation_models()
        
        return {
            'status': 'healthy',
            'opensearch_status': cluster_health.get('status', 'unknown'),
            'timestamp': datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        return {
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }
