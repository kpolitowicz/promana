# Property Management Application - Requirements

## Overview

This application is designed to manage rental properties, tenants, and associated utility billing. The system supports multiple properties, each with associated tenants, and handles the complex workflow of generating monthly payslips that account for fixed rent and variable utilities, while managing payment forecasts and actual payment adjustments.

## Core Entities

### Properties
- Multiple properties can be managed in the system
- Each property can have associated tenants
- Properties have associated utilities (heating, water, waste, energy)

### Tenants
- Multiple tenants can be managed
- Each tenant is associated with one or more properties
- Tenants receive monthly payslips

### Utilities
- Each property can have multiple utility provider entities
- Utility providers can manage different types of utilities (e.g., heating, water, waste, energy, etc.)
- Some utility providers manage multiple utility types (e.g., one provider may handle heating, water, and waste)
- Utilities vary from month to month
- Utilities are allocated 100% to the tenant of the associated property
- Examples of utility types include: heating, water, waste, energy, etc.

### Utility Types
- Utility types are managed through the web interface
- Users can create and delete custom utility type names (e.g., "Heating", "Water", "Waste", "Energy")
- Utility types must have unique names
- Utility types are associated with utility providers to define which utilities each provider manages
- Deleting a utility type removes it from all utility providers that use it

### Utility Provider Configuration
- Each utility provider entity has a **forecast behavior** property that determines what happens when no new forecast is received:
  - **Zero After Expiry**: After the forecast period expires, if no new forecast is received, payment becomes $0 for subsequent months until a new forecast arrives
  - **Carry Forward**: If no new forecast is received for a month, the system uses the same amounts as the previous month (carries forward the last known forecast values)
- Utility providers are nested under properties
- Multiple utility types can be assigned to each utility provider
- Utility providers can be created, viewed, edited, and deleted

### Payment Forecasts
- Received from utility provider entities (frequency varies by provider, e.g., ~every 3 months, ~every 6 months)
- Each utility provider can send forecasts independently
- Forecasts can cover multiple future months
- **Itemized Forecasts**: Some utility providers (those managing multiple utility types) provide itemized payment forecasts with line items for each utility type (e.g., waste: $X, water: $Y, heating: $Z)
- Forecasts affect tenant payslip calculations

### Actual Payments & Meter Readings
- Utility provider entities provide updates on actual utility usage
- Providers can provide meter readings and actual usage calculations
- Can include calculations for past periods showing differences between:
  - Amounts paid (prognosed/forecasted)
  - Actual usage according to meters
- These differences need to be accounted for in future payslips

### Payslips
- Generated monthly for each tenant
- Include:
  - Fixed rent amount (editable per property/tenant)
  - Variable utilities for that month
- Format: HTML/web view
- Adjustments from previous months are included when payments arrive after payslip generation

### Vendor Payments
- Each utility provider entity: Monthly amounts owed for their respective utilities
- Multiple utility providers can be associated with each property

## Workflows & Features

### 1. Property & Tenant Management
- Support multiple properties
- Support multiple tenants
- Associate tenants with properties through web interface
- Assign tenants to properties with rent amount configuration
- Edit or remove tenant-property assignments
- Manage rent amounts (editable per property/tenant)
- Create, edit, and delete properties
- Create, edit, and delete tenants
- View property details including assigned tenants and utility providers
- View tenant details including associated properties

### 2. Monthly Payslip Generation
- Generate payslips for tenants each month
- **Month and Due Date Override**: Ability to override the target month (default: next month) and due date (default: 10th of the target month)
- **Automatic Regeneration**: Payslip line items automatically regenerate when month or due date is changed in the form
- Payslips include:
  - Fixed rent (configurable per property/tenant)
  - Variable utilities for the target month (calculated based on active forecasts and forecast behavior rules)
  - **Payment Differences from Previous Month**: Automatically calculated and included as line items:
    - **Underpayment (Arrears)**: When tenant paid less than the previous month's payslip total, a positive amount line item is added
    - **Overpayment (Credit)**: When tenant paid more than the previous month's payslip total, a negative amount line item (credit) is added
    - Payment differences are calculated by comparing the previous month's payslip total with all payments made in that month (based on paid_date)
    - Multiple payments in the same month are summed together
    - No difference line item is added if payments exactly match the payslip total
  - **Forecast Adjustments from Previous Month**: Automatically calculated and included as line items when new forecasts are received after a payslip was generated:
    - **Adjustment (Wyrównanie)**: When a new forecast is received for a month after the payslip was already generated, the difference between the payslip amounts and the new forecast amounts is calculated
    - The adjustment compares what was included in the previous month's payslip (per utility provider and line item) with the most recent forecast for that month
    - Adjustments are calculated per utility provider and summed across all providers
    - Positive adjustments indicate the tenant was undercharged (needs to pay more)
    - Negative adjustments indicate the tenant was overcharged (credit/refund)
    - No adjustment line item is added if the total difference is zero
- Utility amounts are determined by:
  - Active forecasts for the target month (if available)
  - Forecast behavior rules when no forecast exists (zero after expiry or carry forward)
- Payslips are viewable as HTML/web pages in tabular format with line items and total
- Payslips can be generated, saved, and deleted through web interface
- **Configurable Labels**: Payment difference labels (Arrears, Credit) and forecast adjustment label (Wyrównanie) are configurable in the Payslip model

### 3. Utility Update Workflow

#### Utility Provider Updates
- Receive updates from utility provider entities (frequency varies by provider)
- Updates can include:
  - Payment forecasts for future periods (may be itemized with line items per utility type)
  - Actual usage calculations for past periods
  - Meter readings and actual usage calculations
  - Differences between forecasted and actual amounts
- Each utility provider can send updates independently
- Update frequency can vary by provider (e.g., some providers send updates ~every 3 months, others ~every 6 months)
- Providers managing multiple utility types may send itemized forecasts breaking down amounts by utility type

### 4. Forecast Entry
- System must allow entry of payment forecasts from any utility provider entity through web interface
- Each property can have multiple utility providers
- Forecasts have an issued date
- **Forecast Line Items**: Each forecast can have multiple line items with:
  - Name (e.g., "Forecast", "Settlement" for settlement/differences)
  - Amount (can be positive, negative, or zero - negative amounts represent refunds/credits)
  - Due date (payment due date)
- All line items within a forecast must be enterable and trackable separately
- Line items can be added or removed dynamically through the web interface
- Forecasts can be updated or corrected
- Create, edit, and delete forecasts through web interface

### 5. Balance Sheets
- **Tenant Balance Sheets**: Consolidated monthly balance sheets for each tenant
  - Persisted balance sheet entries for each month showing:
    - Month (beginning of month date)
    - Due date (from payslip or default 10th of month)
    - Owed: Sum of all payslip line item amounts for the month (including late-arriving forecasts)
    - Paid: Sum of all tenant payment amounts where paid_date falls within the month
    - Balance: Difference between owed and paid
  - Balance sheets are accessible from the property tenant show page
  - "Update" button generates missing months for older entries (never updating numbers in them) and recalculates the current month's entry
  - Current balance (sum of all balance sheet balances) is displayed at the top of the page
  - Balance sheets are ordered by due_date descending
  - Late-arriving forecasts: If a forecast is received after a payslip was generated for a month, the forecast amounts are included in the balance sheet for that month (not carried over to the next month)
- **Utility Provider Balance Sheets**: Consolidated monthly balance sheets for each utility provider
  - Persisted balance sheet entries for each month showing:
    - Month (beginning of month date)
    - Due date (from earliest forecast line item for the month or default 10th of month)
    - Owed: Sum of all forecast line item amounts due in the month
    - Paid: Sum of all utility payment amounts where paid_date falls within the month
    - Balance: Difference between owed and paid
  - Balance sheets are accessible from the utility provider show page
  - "Update" button generates missing months for older entries (never updating numbers in them) and recalculates the current month's entry
  - Current balance (sum of all balance sheet balances) is displayed at the top of the page
  - Balance sheets are ordered by due_date descending

### 6. Payment Tracking & Adjustment Handling
- **Tenant Payment Tracking**: Track payments received from tenants
  - Record payment amount and paid date for each tenant payment
  - Payments are associated with property-tenant relationships
  - Full CRUD interface for managing tenant payments
  - Accessible from property show page (Payments link next to Payslips)
  - Payments are matched to payslips by checking if paid_date falls within the payslip's month
- **Utility Payment Tracking**: Track payments made to utility providers
  - Record payment amount and paid date for each utility provider payment
  - Payments are associated with utility providers and properties
  - Full CRUD interface for managing utility payments
  - Accessible from utility provider show page
- **Automatic Payment Difference Calculation**: 
  - **Critical Workflow**: Payments are often received AFTER payslips have been generated for that month
  - When generating a payslip, the system automatically:
    - Finds the previous month's payslip (if it exists)
    - Finds all tenant payments made in that month (based on paid_date)
    - Calculates the difference between payslip total and total payments
    - Includes a difference line item in the current month's payslip:
      - **Underpayment (Arrears)**: Positive amount when tenant paid less than payslip total
      - **Overpayment (Credit)**: Negative amount (credit) when tenant paid more than payslip total
  - Multiple payments in the same month are automatically summed
  - No difference line item is added if payments exactly match the payslip total
  - Payment differences are configurable via Payslip model class methods
- **Automatic Forecast Adjustment Calculation**:
  - **Critical Workflow**: New forecasts are often received AFTER payslips have been generated for that month
  - When generating a payslip, the system automatically:
    - Finds the previous month's payslip (if it exists)
    - For each utility provider, extracts what amounts were included in the previous payslip
    - Finds the most recent forecast for that month (preferring forecasts issued after the payslip was created)
    - Calculates the difference between payslip amounts and new forecast amounts for each line item
    - Sums all differences across all utility providers
    - Includes an adjustment line item (Wyrównanie) in the current month's payslip if the total difference is non-zero
  - Adjustments account for changes in forecast amounts after payslip generation
  - Positive adjustments indicate undercharging (tenant owes more)
  - Negative adjustments indicate overcharging (credit to tenant)
  - Forecast adjustments are configurable via Payslip model class methods

### 7. Vendor Payment Reports
- Generate monthly reports showing amounts owed to each utility provider entity
- Each property can have multiple utility providers
- Reports should reflect:
  - Forecasted amounts
  - Actual amounts (when available)
  - Any adjustments or differences

## Business Rules

1. **Utility Allocation**: Utilities are allocated 100% to the tenant of the associated property (per-property allocation)

2. **Rent Management**: Rent amounts are changeable and can be updated per property/tenant

3. **Payslip Format**: Payslips are generated as HTML/web views (not PDF or email)

4. **Single-User Application**: No authentication or multi-user support required

5. **Payment Adjustments**: When payments arrive after payslip generation, the difference is automatically calculated and included in the next month's payslip as a line item (Arrears for underpayment, Credit for overpayment)
6. **Forecast Adjustments**: When new forecasts are received for a month after the payslip was already generated, the difference between the payslip amounts and the new forecast amounts is automatically calculated and included in the next month's payslip as an adjustment line item (Wyrównanie)

7. **Forecast Impact**: Payment forecasts affect tenant payslip calculations for the months they cover

8. **Historical Adjustments**: Past period calculations (differences between forecasted and actual) must be incorporated into future payslips

9. **Forecast Behavior**: Each utility provider has a forecast behavior setting that determines payment calculation when no new forecast is received:
   - **Zero After Expiry**: Payment becomes $0 after forecast period expires until a new forecast is received
   - **Carry Forward**: Uses the same amounts as the previous month when no new forecast is received

## Data Relationships

```
Property
  ├── Tenant(s)
  ├── Rent (fixed, editable)
  ├── Tenant Payments (payments received from tenants)
  └── Utility Providers (multiple)
      ├── Utilities (various types: heating, water, waste, energy, etc.)
      ├── Forecasts (future months)
      │   └── Itemized Forecasts (line items per utility type)
      └── Utility Payments (payments made to providers)

Payslip (monthly)
  ├── Tenant
  ├── Property
  ├── Fixed Rent
  ├── Utilities (variable, from multiple providers)
  └── Adjustments (from previous months)

Utility Provider Entity
  ├── Associated with Property
  ├── Forecast Behavior (zero after expiry | carry forward)
  ├── Utility Types (heating, water, waste, energy, etc.)
  ├── Forecasts (future months)
  │   └── Itemized Forecasts (line items per utility type)
  └── Utility Payments (payments made to provider)
```

## User Interface

- **Web-based Interface**: Single-page application with navigation bar
- **CRUD Operations**: Full create, read, update, delete functionality for all entities:
  - **Properties Management** (in Settings): Create, edit, delete properties (with address)
  - **Properties Viewing** (in Properties): View-only access to properties with associated payslips, forecasts, and balance sheets
  - Tenants (with contact information)
  - Utility Types (custom names for utility categories)
  - Utility Providers (with forecast behavior and utility type associations, nested under properties)
  - Property-Tenant Assignments (with rent amounts, nested under property settings)
  - Forecasts (with itemized line items)
  - Tenant Payments (payments received from tenants, tracked by paid date and amount, nested under property-tenants)
  - Utility Payments (payments made to utility providers, tracked by paid date and amount, nested under utility providers)
- **Payslip Management**: View, generate, save, and delete payslips through web interface
  - Generate payslips with automatic calculation of utilities based on forecasts
  - Override month and due date during generation
  - Automatic regeneration of line items when month/due date changes
  - View payslips in tabular format with line items and totals
- **Navigation**: Easy navigation between all major sections with dropdown menus
  - House icon in navbar links to home page (properties index)
  - **Properties dropdown**: Hover-activated menu showing all properties from the database for quick access to individual property pages
  - **Settings dropdown**: Hover-activated menu with three configuration options:
    - Properties: Property CRUD management
    - Tenants: Tenant management
    - Utility Types: Utility type management
  - Dropdowns use Stimulus JS controllers for smooth hover interactions
  - Navigation is divided into:
    - **Properties Section**: View-only interface for viewing property data (payslips, forecasts, balance sheets)
    - **Settings Section**: Management interface for property CRUD operations, tenant assignment, and utility provider management
- **Data Management**: Ability to delete entities with confirmation dialogs
  - Delete confirmations show entity name and warn that action cannot be undone
  - All delete operations use Turbo-compatible confirmation dialogs
- **Form Validation**: Client and server-side validation with error messages

## Technical Implementation

- **Framework**: Ruby on Rails 8.1
- **Ruby Version**: 4.0.0
- **Database**: SQLite3 (development/test), with support for production database configuration
- **Styling**: Tailwind CSS for responsive, modern UI
- **Testing**: RSpec for comprehensive test coverage (263 examples, 0 failures)
- **Code Quality**: StandardRB for Ruby code style enforcement
- **Production Deployment**: 
  - **`bin/prod` script**: Production server startup script
    - Automatically runs database migrations
    - Precompiles assets (Propshaft)
    - Starts Rails server in production mode
    - Supports PORT, SKIP_MIGRATE, and SKIP_ASSETS environment variables
  - **`bin/docker-prod` script**: Docker-based production deployment
    - Builds Docker image and runs container on port 8080 (configurable via PORT)
    - Automatically generates SECRET_KEY_BASE if not provided
    - Mounts `./storage` directory as volume for SQLite database persistence
    - Supports SKIP_BUILD, SKIP_MIGRATE, and SKIP_ASSETS environment variables
    - SQLite database files persist on host machine (not copied into container)
- **Architecture**: Service objects for complex business logic (ForecastCalculator, PayslipGenerator)
- **Currency Configuration**: Configurable currency symbol and position (before/after amount) via environment variables:
  - `CURRENCY_SYMBOL`: Currency symbol (default: "zł" for PLN)
  - `CURRENCY_POSITION`: Position of symbol relative to amount - "before" or "after" (default: "after")
  - Configured in `config/initializers/currency.rb`
- **Payslip Configuration**: Configurable labels in Payslip model:
  - Header labels: `name_header` (default: "Pozycja"), `amount_header` (default: "Kwota"), `total_header` (default: "Razem")
  - Payment difference labels: `underpayment_label` (default: "Zaległe"), `overpayment_label` (default: "Nadpłata")
  - Forecast adjustment label: `adjustment_label` (default: "Wyrównanie")
  - Rent label: `rent_label` (default: "Czynsz")

## Future Considerations

- Support for multiple tenants per property (if needed)
- Export functionality for payslips and reports (PDF, CSV)
- Historical data tracking and reporting
- Notification system for when forecasts or actuals are received
- XLSX file import functionality for bulk data entry
- Vendor payment reports UI
- Payment adjustment calculations (automatically calculating differences between payslips and actual payments)

