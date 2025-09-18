class ApiEndpoints {

  static const String baseUrl = 'https://enable-be-production.up.railway.app/api/v1';
  // static const String baseUrl = 'http://localhost:5000/api/v1';

  // Auth endpoints
  static const String loginUrl = '/auth/login';
  static const String registerAgency = "/auth/register";
  static const String registerUrl = '/auth/register/user';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String loginUserUrl = '/auth/login/user';

  // User endpoints
  static const String singleUser="/agency/user/";
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String changePassword = '/user/change-password';

  // Agency endpoints
  static const String agencyUsers = '/agency/users';
  static const String editAgency = '/agency/edit/{id}';
  static const String getDocumentCount = '/agency/document-count/{agencyId}';

  // Data endpoints
  static const String getDMCs = '/dmc/{agencyId}';
  static const String getProducts = '/product/{agencyId}';
  static const String getExternalProducts = '/external-product/{agencyId}';
  static const String getServiceProviders = '/service-provider/{agencyId}';
  static const String getExperiences = '/experience/{agencyId}';

  // File upload endpoints
  static const String uploadFileToAgency = '/upload/agency';

  // Conversation endpoints
  static const String getConversations = '/conversation/{agencyId}';
  
  // Batch ingestion endpoints
  static const String batchIngestionEnqueue = '/batch-ingestion/enqueue';
  static const String batchIngestionStatus = '/batch-ingestion/status';
  static const String batchIngestionProgress = '/batch-ingestion/progress';
  static const String batchIngestionCheckFiles = '/batch-ingestion/check-files';

  static const String getAgencyFiles = '/upload/agency/{agencyId}';
  static const String deleteAgencyFile = '/upload/agency/{agencyId}/{fileId}';

  // Google Drive endpoints
  static const String googleDriveAuthUrl = '/google-drive/auth-url';
  static const String googleDriveCallback = '/google-drive/callback';
  static const String googleDriveAssociateTokens = '/google-drive/associate-tokens';
  static const String googleDriveFiles = '/google-drive/files';
  static const String googleDriveFilesMore = '/google-drive/files/more';
  static const String googleDriveFileContent = '/google-drive/files/{fileId}/content';
  static const String googleDriveFilePreview = '/google-drive/files/{fileId}/preview';
  static const String googleDriveFolderContents = '/google-drive/folders/{folderId}/contents';
  static const String googleDriveDisconnect = '/google-drive/disconnect';
  static const String googleDriveStatus = '/google-drive/status';

  // Dropbox endpoints
  static const String dropboxAuthUrl = '/dropbox/auth-url';
  static const String dropboxCallback = '/dropbox/callback';
  static const String dropboxAssociateTokens = '/dropbox/associate-tokens';
  static const String dropboxFiles = '/dropbox/files';
  static const String dropboxStatus = '/dropbox/status';

  // OPENAI
  static const String chatWithAgentUrl="/agent/chat";
  
  // Search mode endpoints
  static const String searchModeUrl="/search-mode";
  
  // Search endpoints
  static const String searchExperiences = '/search/experiences';
  static const String searchProducts = '/search/products';
  static const String searchDatabase = '/search/database';
  static const String searchItineraries = '/search/itineraries';
  static const String searchVICs = '/search/vics';
}