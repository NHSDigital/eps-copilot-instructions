# Copilot Instructions for Python Files in `packages/slackBotFunction`

## Purpose
These instructions guide GitHub Copilot to generate high-quality, maintainable Python code, with modular architecture, service layers, and test coverage.

## General Guidelines
- Use Python 3.9+ syntax and typing.
- Follow PEP8 for formatting and naming conventions.
- Prefer explicit imports and avoid wildcard imports.
- Use docstrings for all public functions, classes, and modules.
- Organize code into logical modules: `core`, `services`, `utils`.
- Write modular, testable code with clear separation of concerns.
- Use dependency injection for services and external integrations.
- Handle exceptions gracefully and log errors using the standard `logging` module.
- NEVER hardcode secrets or configuration; use environment variables or config files.

## File/Folder Specific Instructions
### `app/handler.py`
- Main entry point for AWS Lambda handler.
- Validate and parse incoming Slack events.
- Delegate business logic to service or core modules.
- Return AWS Lambda-compatible response objects.

### `app/core/`
- Implement core business logic and reusable components.
- Avoid direct dependencies on Slack or AWS SDKs.
- Write pure functions where possible.

### `app/services/`
- Integrate with external APIs (e.g., Bedrock, DynamoDB).
- Use abstraction layers for AWS services.
- Mock external dependencies in tests.

### `app/utils/`
- Provide utility functions for common tasks (e.g., string manipulation, config loading).
- Keep utilities stateless and reusable.

### `tests/`
- Use `pytest` for all tests.
- Name test files and functions descriptively (e.g., `test_handler_utils.py`, `test_forward_to_lambda`).
- Mock AWS and Slack APIs using `pytest-mock` or `unittest.mock`.
- Ensure coverage for error cases and edge conditions.

## Best Practices
- Use type hints and `Optional` where appropriate.
- Prefer f-strings for string formatting.
- Use context managers for resource handling.
- Write unit tests for all new code and maintain high coverage.
- Document public APIs and expected input/output formats.
- Avoid global state; prefer passing dependencies explicitly.

## Example Docstring
"""
Handles incoming Slack event and routes to appropriate service.
Args:
    event (dict): Slack event payload.
    context (LambdaContext): AWS Lambda context object.
Returns:
    dict: AWS Lambda response object.
Raises:
    ValueError: If event payload is invalid.
"""

## Prohibited Patterns
- No direct AWS credentials or secrets in code.
- No print statements for logging (use `logging` instead).
- No business logic in handler files; delegate to services/core.

## References
- [PEP8](https://peps.python.org/pep-0008/)
- [pytest Documentation](https://docs.pytest.org/en/stable/)

---
