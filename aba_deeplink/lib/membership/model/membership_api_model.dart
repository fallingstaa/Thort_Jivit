class MembershipApiResponse {
  static const String MEMBERSHIP_API_RESPONSE_ERROR_TYPE = 'type';
  static const String MEMBERSHIP_API_RESPONSE_ERROR_MESSAGE = 'message';

  static const String MEMBERSHIP_API_RESPONSE_ERROR_TYPE_ACCESS_TOKEN_ERROR = 'Access Token Error';

  final bool isSuccessful;
  final String type;
  final String message;

  MembershipApiResponse.fromJson(Map<String, dynamic> data, int status)
      : this.isSuccessful = status >= 200 && status < 300,
        this.type = data[MEMBERSHIP_API_RESPONSE_ERROR_TYPE] ?? 'Something Went Wrong',
        this.message = data[MEMBERSHIP_API_RESPONSE_ERROR_MESSAGE] ??
            'We Are Unable To Process Your Request Right Now. Please Try Again Later.';
}
