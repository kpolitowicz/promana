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
- Each utility provider entity has a **forecast behavior** property that determines what happens when no new forecast is received - ✅ Implemented:
  - **Zero After Expiry**: After the forecast period expires, if no new forecast is received, payment becomes $0 for subsequent months until a new forecast arrives - ✅ Implemented
  - **Carry Forward**: If no new forecast is received for a month, the system uses the same amounts as the previous month (carries forward the last known forecast values) - ✅ Implemented
- Utility providers are nested under properties - ✅ Implemented
- Multiple utility types can be assigned to each utility provider - ✅ Implemented
- Utility providers can be created, viewed, edited, and deleted - ✅ Implemented

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
- Support multiple properties - ✅ Implemented
- Support multiple tenants - ✅ Implemented
- Associate tenants with properties through web interface - ✅ Implemented
- Assign tenants to properties with rent amount configuration - ✅ Implemented
- Edit or remove tenant-property assignments - ✅ Implemented
- Manage rent amounts (editable per property/tenant) - ✅ Implemented
- Create, edit, and delete properties - ✅ Implemented
- Create, edit, and delete tenants - ✅ Implemented
- View property details including assigned tenants and utility providers - ✅ Implemented
- View tenant details including associated properties - ✅ Implemented

### 2. Monthly Payslip Generation
- Generate payslips for all tenants each month
- Payslips include:
  - Fixed rent (configurable per property/tenant)
  - Variable utilities for the current month (calculated based on active forecasts and forecast behavior rules)
  - Adjustments from previous months (when applicable)
- Utility amounts are determined by:
  - Active forecasts for the month (if available)
  - Forecast behavior rules when no forecast exists (zero after expiry or carry forward)
- Payslips are viewable as HTML/web pages
- Payslips can be generated/regenerated as needed

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
- Forecasts can span multiple months
- **Itemized Forecast Entry**: For utility providers managing multiple utility types, the system must support entering itemized forecasts with individual line items for each utility type (e.g., waste: $X, water: $Y, heating: $Z)
- All line items within an itemized forecast must be enterable and trackable separately
- Forecasts affect tenant payslip calculations for future months
- Forecasts can be updated or corrected
- Create, edit, and delete forecasts through web interface

### 5. Payment Timing & Adjustment Handling
- **Critical Workflow**: Payments are often received AFTER payslips have been generated for that month
- When actual payments differ from what was included in the payslip:
  - The difference must be calculated
  - The difference must be accounted for in the NEXT month's payslip
- System must track:
  - What was included in each payslip
  - What was actually paid/received
  - The difference/adjustment amount
  - Application of adjustments to subsequent payslips

### 6. Vendor Payment Reports
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

5. **Payment Adjustments**: When payments arrive after payslip generation, the difference is automatically included in the next month's payslip

6. **Forecast Impact**: Payment forecasts affect tenant payslip calculations for the months they cover

7. **Historical Adjustments**: Past period calculations (differences between forecasted and actual) must be incorporated into future payslips

8. **Forecast Behavior**: Each utility provider has a forecast behavior setting that determines payment calculation when no new forecast is received:
   - **Zero After Expiry**: Payment becomes $0 after forecast period expires until a new forecast is received
   - **Carry Forward**: Uses the same amounts as the previous month when no new forecast is received

## Data Relationships

```
Property
  ├── Tenant(s)
  ├── Rent (fixed, editable)
  └── Utility Providers (multiple)
      └── Utilities (various types: heating, water, waste, energy, etc.)

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
  └── Actuals (past periods with differences)

Vendor Payments
  └── Utility Provider Entities (multiple per property)
```

## User Interface

- **Web-based Interface**: Single-page application with navigation bar
- **CRUD Operations**: Full create, read, update, delete functionality for all entities:
  - Properties (with address)
  - Tenants (with contact information)
  - Utility Types (custom names for utility categories)
  - Utility Providers (with forecast behavior and utility type associations, nested under properties)
  - Property-Tenant Assignments (with rent amounts, nested under properties)
  - Forecasts (with itemized line items)
- **Payslip Management**: View and generate payslips through web interface
- **Navigation**: Easy navigation between all major sections
- **Data Management**: Ability to delete entities with confirmation dialogs
- **Form Validation**: Client and server-side validation with error messages

## Technical Implementation

- **Framework**: Ruby on Rails 8.1
- **Ruby Version**: 4.0.0
- **Database**: SQLite3 (development/test), with support for production database configuration
- **Styling**: Tailwind CSS for responsive, modern UI
- **Testing**: RSpec for comprehensive test coverage
- **Code Quality**: StandardRB for Ruby code style enforcement
- **Architecture**: Service objects for complex business logic (ForecastCalculator, PayslipGenerator)

## Future Considerations

- Support for multiple tenants per property (if needed)
- Export functionality for payslips and reports (PDF, CSV)
- Historical data tracking and reporting
- Notification system for when forecasts or actuals are received
- XLSX file import functionality for bulk data entry
- Vendor payment reports UI
- Actual payment entry interface

