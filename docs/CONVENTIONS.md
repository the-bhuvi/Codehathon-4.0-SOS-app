# Naming Conventions

To maintain consistency throughout the SafeAlert project, please follow these naming conventions:

## 📁 Folders
- Use **lowercase** with underscores or hyphens if necessary (e.g., `ai_backend`, `ui_components`).
- High-level project folders should be single words where possible (`mobile`, `backend`, `dashboard`).

## 📄 Files
- **JavaScript/React:** `PascalCase.jsx` for components, `camelCase.js` for utilities.
- **Python:** `snake_case.py`.
- **Dart/Flutter:** `snake_case.dart` (consistent with Flutter standards).
- **CSS:** `snake_case.css` or `camelCase.css` (be consistent within the module).
- **Markdown:** `UPPERCASE.md` for root docs (`README.md`, `LICENSE.md`) and `snake_case.md` for others.

## 💻 Code
- **Variables & Functions:** `camelCase` (JS/Dart), `snake_case` (Python).
- **Classes:** `PascalCase` (All languages).
- **Constants:** `UPPER_SNAKE_CASE` (All languages).
- **Private Variables:** Prefix with an underscore `_variableName` (Flutter/Dart).

## 🚀 Git
- **Branch Naming:** `feature/description`, `fix/description`, `chore/description`.
- **Commit Messages:** Use [Conventional Commits](https://www.conventionalcommits.org/) (e.g., `feat: add shake detection`).
