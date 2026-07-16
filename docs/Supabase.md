# Database and Supabase Integration

QuickFix leverages SQL databases for storage and indexing.

## 1. System Database Engine

The system uses a relational database structure designed to support:
- **Spatial Queries**: Geolocation indexes to search for shops within a 5-10km radius of the user's latitude and longitude coordinates.
- **Transaction Consistency**: Ensuring that booking status changes and wallet money additions occur atomically, preventing double-spending.

---

## 2. API / Backend Operations

The backend system is designed to interface with database servers (such as PostgreSQL on Supabase or generic SQL engines) through clean REST models:
- **Category Querying**: Retrieves categories.
- **Provider Status**: Providers update their availability which updates the database.
- **Bookings Sync**: Synchronizes client history instantly, resolving offline syncing through background API fetches on startup.
