# Python Copilot Instructions for EPS Assist Me

---
description: 'Brief description of the instruction purpose and scope'
applyTo: '*.py*'
---

## Project Context
This is an AWS Lambda-based Slack bot application that integrates with Amazon Bedrock for AI-powered assistance. The Python code follows serverless patterns and AWS best practices.

## Code Style & Conventions

### Import Organization
Follow this import order:
1. Standard library imports
2. Third-party imports (boto3, slack_bolt, etc.)
3. AWS Lambda Powertools imports
4. mypy-boto3 type imports
5. Local application imports (app.*)

Example:
```python
import json
import os
from typing import Any, Dict
import boto3
from aws_lambda_powertools import Logger
from mypy_boto3_dynamodb.service_resource import Table
from app.core.config import get_logger
```

### Type Hints & mypy-boto3
- Always use type hints for function parameters and return values
- Use mypy-boto3 types for AWS service clients and resources
- Import specific types from mypy_boto3_* packages

```python
from mypy_boto3_bedrock_agent_runtime import AgentsforBedrockRuntimeClient
from mypy_boto3_bedrock_agent_runtime.type_defs import RetrieveAndGenerateResponseTypeDef

def query_bedrock(user_query: str, session_id: str = None) -> RetrieveAndGenerateResponseTypeDef:
```

### Docstrings
Use descriptive docstrings that explain:
- What the function does
- Key business logic or AWS service interactions
- Important parameters and return values

```python
def query_bedrock(user_query: str, session_id: str = None) -> RetrieveAndGenerateResponseTypeDef:
    """
    Query Amazon Bedrock Knowledge Base using RAG (Retrieval-Augmented Generation)

    This function retrieves relevant documents from the knowledge base and generates
    a response using the configured LLM model with guardrails for safety.
    """
```

### Module-level Docstrings
Include module-level docstrings for context:
```python
"""
Main Lambda handler - dual-purpose function for Slack bot operations

This Lambda function serves two purposes:
1. Handles incoming Slack events (webhooks) via API Gateway
2. Processes async operations when invoked by itself to avoid timeouts
"""
```

## AWS Lambda Patterns

### Handler Functions
- Use AWS Lambda Powertools for logging
- Include proper type hints with LambdaContext
- Use logger decorators for context injection

```python
from aws_lambda_powertools.utilities.typing import LambdaContext

@logger.inject_lambda_context(log_event=True, clear_state=True)
def handler(event: dict, context: LambdaContext) -> dict:
```

### Configuration Management
- Use @lru_cache() for expensive configuration operations
- Load AWS resources and credentials lazily
- Use environment variables for configuration

```python
from functools import lru_cache

@lru_cache()
def get_slack_bot_state_table() -> Table:
    dynamodb = boto3.resource("dynamodb")
    return dynamodb.Table(os.environ["SLACK_BOT_STATE_TABLE"])
```

## AWS Service Integration

### Boto3 Client Creation
Create typed clients with proper region configuration:
```python
client: AgentsforBedrockRuntimeClient = boto3.client(
    service_name="bedrock-agent-runtime",
    region_name=AWS_REGION,
)
```

### Error Handling
- Create custom exceptions for domain-specific errors
- Log errors with context before raising
- Use try/except blocks for AWS service calls

```python
class ConfigurationError(Exception):
    """Raised when there's a configuration issue"""
    pass

try:
    response = client.retrieve_and_generate(**request_params)
except Exception as e:
    logger.error("Failed to query Bedrock", extra={"error": str(e)})
    raise
```

## Logging

### Logger Setup
- Use AWS Lambda Powertools Logger
- Set up logger with service name
- Use structured logging with extra fields

```python
from aws_lambda_powertools import Logger

logger = Logger(service="slackBotFunction")

# In functions
logger.info("Processing request", extra={"session_id": session_id})
logger.error("Operation failed", extra={"error": str(e), "user_id": user_id})
```

## Testing

### Test Structure
- Use pytest as the test framework
- Mock AWS services with unittest.mock
- Follow test_* naming convention
- Group related tests in classes

```python
from unittest.mock import Mock, patch

@patch("slack_bolt.adapter.aws_lambda.SlackRequestHandler")
def test_handler_normal_event(
    mock_handler_class: Mock, 
    mock_slack_app: Mock, 
    lambda_context: Mock
):
    """Test Lambda handler function for normal Slack events"""
```

### Test Coverage
- Maintain high test coverage (configured in pytest.ini)
- Test both success and error scenarios
- Mock external dependencies (AWS services, Slack API)

## File Organization

### Package Structure
Follow this directory structure:
```
app/
├── __init__.py
├── handler.py              # Main Lambda entry point
├── core/
│   ├── __init__.py
│   └── config.py          # Configuration and AWS resource setup
├── services/
│   ├── __init__.py
│   ├── app.py             # Slack app configuration
│   ├── bedrock.py         # AWS Bedrock integration
│   ├── dynamo.py          # DynamoDB operations
│   ├── exceptions.py      # Custom exceptions
│   └── *.py              # Other service modules
├── slack/
│   ├── __init__.py
│   ├── slack_events.py    # Slack event handlers
│   └── slack_handlers.py  # Slack command handlers
└── utils/
    ├── __init__.py
    └── *.py              # Utility functions
```

## Slack Bot Patterns

### Event Handling
- Use slack-bolt framework patterns
- Implement lazy listeners for long-running operations
- Handle both events and interactive actions

```python
from slack_bolt.adapter.aws_lambda import SlackRequestHandler

app = get_app(logger=logger)
slack_handler = SlackRequestHandler(app)
return slack_handler.handle(event, context)
```

### Async Processing
- Use Lambda self-invocation for operations > 3 seconds
- Pass context in event payload for async processing
- Acknowledge Slack events quickly to avoid timeouts

## Environment Variables
Common environment variables used in the project:
- `SLACK_BOT_TOKEN_PARAMETER` - SSM parameter for Slack bot token
- `SLACK_SIGNING_SECRET_PARAMETER` - SSM parameter for Slack signing secret
- `SLACK_BOT_STATE_TABLE` - DynamoDB table name
- `AWS_REGION` - AWS region
- `KNOWLEDGEBASE_ID` - Bedrock knowledge base ID
- `RAG_MODEL_ID` - Bedrock model ARN
- `GUARD_RAIL_ID` - Bedrock guardrail ID

## Security & Best Practices
- Store secrets in AWS SSM Parameter Store, not environment variables
- Use IAM roles and policies for least privilege access
- Implement input validation for user queries
- Use Bedrock guardrails for AI safety
- Log sensitive operations for audit trails

## Dependencies
Key dependencies used in the project:
- `boto3` - AWS SDK
- `mypy-boto3-*` - Type stubs for AWS services
- `slack-bolt` - Slack framework
- `aws-lambda-powertools` - AWS Lambda utilities
- `pytest` - Testing framework
- `pytest-mock` - Mocking utilities
- `moto` - AWS service mocking for tests