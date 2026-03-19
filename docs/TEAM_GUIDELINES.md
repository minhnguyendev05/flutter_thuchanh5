# Expense Tracker Team Guidelines

## Folder Structure

- lib/models: Data models and JSON mapping.
- lib/services: Local storage, auth, and API abstraction layer.
- lib/providers: Application state and business logic.
- lib/screens: Full pages for each app flow.
- lib/widgets: Reusable UI components.
- lib/utils: Routes, formatter, constants, helper functions.

## Naming Convention

- File names: snake_case (example: transaction_provider.dart).
- Class names: PascalCase (example: TransactionProvider).
- Variables/functions: lowerCamelCase.
- Constants: lowerCamelCase with static const in utility classes.

## File Separation Rules

- One primary class per file.
- UI widgets in screens/widgets only.
- Data conversion code in models only.
- Storage/API calls in services only.

## Clean Architecture Rules

- Do not write business logic directly in UI build methods.
- UI calls provider methods for all CRUD operations.
- Providers should only call services, not directly access plugins from UI.
- Every async process should expose loading/error state for UI.

## Git Workflow

- Branches:
  - main: stable release branch.
  - develop: integration branch for sprint.
  - feature/<task-name>: feature branches per member.
- Commit style:
  - feat: add new feature.
  - fix: bug fix.
  - refactor: code cleanup without behavior changes.
  - docs: update documentation.
  - chore: tooling/config changes.
- Keep each commit focused on one logical change.
