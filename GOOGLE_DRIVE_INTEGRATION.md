# Google Drive Integration

This document describes the Google Drive integration implemented in the Enable web application.

## Overview

The Google Drive integration allows users to:
- Connect their Google Drive account
- View files from their Google Drive
- Open files in the browser
- Disconnect their Google Drive account

## Features

### 1. Google Drive Connection
- Users can connect their Google Drive account through OAuth2 authentication
- The connection status is displayed in the account settings
- Last sync time is shown when connected

### 2. File Management
- View all files from the connected Google Drive account
- See file details including name, size, and modification date
- Open files directly in the browser
- File icons are displayed based on file type

### 3. Error Handling
- Proper error messages for connection failures
- Loading states during operations
- Retry functionality for failed operations

## Implementation Details

### Backend Integration
The frontend integrates with the following backend endpoints:

- `GET /api/v1/google-drive/auth-url` - Get OAuth URL
- `GET /api/v1/google-drive/callback` - Handle OAuth callback
- `GET /api/v1/google-drive/files` - Get user's files
- `GET /api/v1/google-drive/files/more` - Get more files (pagination)
- `DELETE /api/v1/google-drive/disconnect` - Disconnect Google Drive
- `GET /api/v1/google-drive/status` - Get connection status

### Frontend Components

#### 1. GoogleDriveController
Handles all API calls to the backend for Google Drive operations.

#### 2. GoogleDriveProvider
Manages the state of Google Drive integration including:
- Connection status
- File list
- Loading states
- Error handling

#### 3. Account Screen Integration
The account screen shows:
- Google Drive connection status
- Connect/Disconnect button
- Last sync time
- "View Files" button when connected

#### 4. Google Drive Files Screen
Dedicated screen for viewing Google Drive files with:
- File list with icons
- File details (size, modification date)
- Open in browser functionality
- Refresh capability

## Usage

### Connecting Google Drive
1. Navigate to Account > Integrations
2. Click "Connect" next to Google Drive
3. Complete the OAuth flow in your browser
4. Return to the application

### Viewing Files
1. Once connected, click "View Files" in the account screen
2. Browse your Google Drive files
3. Click the open icon to view files in the browser

### Disconnecting
1. Go to Account > Integrations
2. Click "Disconnect" next to Google Drive
3. Confirm the disconnection

## File Types Supported

The application displays different icons for various file types:
- Folders (amber folder icon)
- Images (green image icon)
- Videos (red video icon)
- Audio files (purple audio icon)
- PDFs (red PDF icon)
- Documents (blue document icon)
- Spreadsheets (green table icon)
- Presentations (orange slideshow icon)
- Other files (grey file icon)

## Error Handling

The integration handles various error scenarios:
- Network connectivity issues
- Authentication failures
- API errors
- File access permissions

Error messages are displayed to the user with retry options where appropriate.

## Security

- OAuth2 authentication ensures secure access
- Tokens are stored securely on the backend
- No sensitive data is stored in the frontend
- Automatic token refresh is handled by the backend

## Dependencies

The Google Drive integration uses the following packages:
- `url_launcher` - For opening URLs in the browser
- `provider` - For state management
- `dio` - For HTTP requests
- `dartz` - For functional programming (Either type)

## Testing

Run the integration tests with:
```bash
flutter test test/google_drive_integration_test.dart
```

## Future Enhancements

Potential improvements for the Google Drive integration:
- File upload to Google Drive
- File search functionality
- Folder navigation
- File sharing capabilities
- Offline file access
- File synchronization status 