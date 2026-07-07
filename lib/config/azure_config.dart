/// Production API for Van Dwellers (Azure Functions).
class AzureConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://func-vandwellers-mk01.azurewebsites.net',
  );
}
