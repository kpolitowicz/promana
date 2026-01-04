# Promana

A property management application for managing rental properties, tenants, and utility billing. The system handles monthly payslip generation with automatic calculation of fixed rent and variable utilities, payment tracking, and balance sheet management.

For detailed feature specifications and business requirements, see [REQUIREMENTS.md](REQUIREMENTS.md).

## Requirements

- **Ruby**: 4.0.0 (see `.ruby-version`)
- **Rails**: 8.1.1
- **Database**: SQLite3
- **Node.js**: For Tailwind CSS compilation (included via tailwindcss-rails gem)
- **Docker**: Optional, for Docker-based production deployment

## Installation

### Option 1: Local Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd promana
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up the database**
   ```bash
   bin/rails db:prepare
   ```

4. **Run the setup script** (optional, starts dev server)
   ```bash
   bin/setup
   ```

### Option 2: Dev Container (VS Code / GitHub Codespaces)

For a containerized development environment, you can use VS Code Dev Containers or GitHub Codespaces:

1. **VS Code Dev Containers**
   - Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
   - Open the repository in VS Code
   - Press `F1` and select "Dev Containers: Reopen in Container"
   - VS Code will build and start the container, then install dependencies automatically

2. **GitHub Codespaces**
   - Click "Code" → "Codespaces" → "Create codespace on main"
   - GitHub will create a cloud-based development environment
   - Dependencies and database setup will run automatically

The dev container uses the same Dockerfile as production, ensuring consistency between development and production environments.

## Development

### Starting the Development Server

```bash
bin/dev
```

This starts both the Rails server and Tailwind CSS watcher. The application will be available at `http://localhost:3000`.

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/property_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

### Code Quality

```bash
# Run StandardRB (Ruby linter)
bundle exec standardrb

# Auto-fix StandardRB issues
bundle exec standardrb --fix
```

## Production

### Option 1: Direct Production Server

Run the production server directly:

```bash
bin/prod
```

This will:
- Run database migrations
- Precompile assets
- Start the Rails server on port 8080 (configurable via `PORT` environment variable)

**Environment Variables:**
- `PORT`: Server port (default: 8080)
- `SKIP_MIGRATE=1`: Skip database migrations
- `SKIP_ASSETS=1`: Skip asset precompilation

### Option 2: Docker Production Deployment

Deploy using Docker for containerized production:

```bash
bin/docker-prod
```

This will:
- Build the Docker image
- Generate `SECRET_KEY_BASE` automatically if not provided
- Start the container on port 8080
- Mount `./storage` directory for SQLite database persistence

**Environment Variables:**
- `PORT`: Host port to map to container (default: 8080)
- `SKIP_BUILD=1`: Skip Docker build (use existing image)
- `SKIP_MIGRATE=1`: Skip database migrations
- `SKIP_ASSETS=1`: Skip asset precompilation (assets already precompiled in image)
- `SECRET_KEY_BASE`: Custom secret key (auto-generated if not provided)

**Container Management:**
```bash
# View logs
docker logs -f promana-container

# Stop container
docker stop promana-container

# Remove container
docker rm promana-container
```

**Important**: The SQLite database files in `./storage/` persist on your host machine, not inside the container. This ensures data persistence across container restarts.

## Navigation

The application features a navigation bar with hover-activated dropdown menus:

- **Home Icon**: Links to the properties index page
- **Properties Dropdown**: Shows all properties for quick access
- **Settings Dropdown**: Access to Properties, Tenants, and Utility Types management

See [REQUIREMENTS.md](REQUIREMENTS.md) for detailed navigation specifications.

## Configuration

### Currency Settings

Configure currency symbol, position, and decimal separator via environment variables:

- `CURRENCY_SYMBOL`: Currency symbol (default: "zł" for PLN)
- `CURRENCY_POSITION`: Position relative to amount - "before" or "after" (default: "after")
- `CURRENCY_SEPARATOR`: Decimal separator - "," or "." (default: ",")

Example:
```bash
export CURRENCY_SYMBOL="$"
export CURRENCY_POSITION="before"
export CURRENCY_SEPARATOR="."
```

### Payslip Labels

Payslip labels are configurable in the `Payslip` model. See [REQUIREMENTS.md](REQUIREMENTS.md) for details.

## Database

The application uses SQLite3 for all environments:

- **Development**: `storage/development.sqlite3`
- **Test**: `storage/test.sqlite3`
- **Production**: `storage/production.sqlite3` (and related cache/queue/cable databases)

### Database Commands

```bash
# Create database and run migrations
bin/rails db:prepare

# Reset database (drops, creates, loads schema, seeds)
bin/rails db:reset

# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback
```

## Project Structure

```
promana/
├── app/
│   ├── controllers/        # Application controllers
│   ├── models/             # ActiveRecord models
│   ├── views/              # ERB templates
│   ├── javascript/         # Stimulus controllers
│   └── helpers/            # View helpers
├── config/                 # Application configuration
├── db/                     # Database migrations and seeds
├── spec/                   # RSpec tests
├── storage/                # SQLite databases and Active Storage files
├── bin/                    # Executable scripts
│   ├── dev                 # Development server
│   ├── prod                # Production server
│   └── docker-prod         # Docker production deployment
└── Dockerfile              # Docker image definition
```

## Testing

The application uses RSpec for comprehensive test coverage. Run the test suite:

```bash
bundle exec rspec
```

## License

[Add your license here]

## Contributing

[Add contributing guidelines here]
