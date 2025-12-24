// import 'dart:convert' show jsonDecode;
// import 'dart:typed_data' show Uint8List;
//
// import 'package:http/http.dart';
//
//
// enum MembershipPaths {
//   client_token,
//   access_token,
//   transactions,
//   transactions_cash,
//   transactions_noncash,
//   order_details,
//   commit_payment,
//   setup_pin_code,
//   register_for_membership,
//   public_membership_info,
//   verified_membership_info,
//   registration_info,
// }
//
// class MembershipPathsOptions {
//   String? orderID;
//   String? membershipID;
//
//   MembershipPathsOptions({this.orderID, this.membershipID});
// }
//
// class MembershipApiHelper {
//   static const String REQUEST_HEADER_CLIENT_ID = 'client_id';
//   static const String REQUEST_HEADER_SECRET_KEY = 'secret_key';
//   static const String REQUEST_HEADER_CONTENT_TYPE = 'content-type';
//
//   static const String CONTENT_TYPE_JSON = 'application/json';
//   static const String CONTENT_TYPE_HTML = 'text/html';
//
//   static const String MEMBERSHIP_RESPONSE_DATA = 'data';
//
//   static final MembershipApiHelper shared = MembershipApiHelper();
//
//   bool _isJsonObject(Response response) =>
//       response.headers[REQUEST_HEADER_CONTENT_TYPE]?.split(';')[0] ==
//           CONTENT_TYPE_JSON &&
//           response.body[0] == '{';
//
//   bool _isText(Response response) =>
//       response.headers[REQUEST_HEADER_CONTENT_TYPE]?.split(';')[0] ==
//           CONTENT_TYPE_HTML;
//
//   Map<String, dynamic> responseToData(Response response) {
//     if (_isJsonObject(response))
//       return jsonDecode(response.body);
//     else {
//       if (_isText(response)) return {MEMBERSHIP_RESPONSE_DATA: response.body};
//
//       return {MEMBERSHIP_RESPONSE_DATA: jsonDecode(response.body)};
//     }
//   }
//
//   String _getMembershipPath({
//     required MembershipPaths path,
//     MembershipPathsOptions? options,
//   }) {
//     switch (path) {
//       case MembershipPaths.client_token:
//         return 'client_token';
//       case MembershipPaths.access_token:
//         return 'memberships/pin/verifications';
//       case MembershipPaths.transactions:
//         return 'memberships/transactions';
//       case MembershipPaths.transactions_cash:
//         return 'memberships/transactions/cash';
//       case MembershipPaths.transactions_noncash:
//         return 'memberships/transactions/noncash';
//       case MembershipPaths.order_details:
//         return 'payments/orders/${options?.orderID}';
//       case MembershipPaths.commit_payment:
//         return 'payments/pay';
//       case MembershipPaths.setup_pin_code:
//         return 'memberships/pin/change';
//       case MembershipPaths.register_for_membership:
//         return 'memberships';
//       case MembershipPaths.public_membership_info:
//         return 'memberships/${options?.membershipID}';
//       case MembershipPaths.verified_membership_info:
//         return 'memberships';
//       case MembershipPaths.registration_info:
//         return 'memberships/registrations/info';
//     }
//   }
//
//   Future<String> _getClientToken() async {
//     final ClientTokenResponse _clientTokenResponse =
//     await AuthHelper.shared.getClientToken();
//     final String _clientToken = _clientTokenResponse.clientToken;
//
//     TokenHelper.shared.setClientToken(_clientToken);
//
//     return _clientToken;
//   }
//
//   Future<Map<String, String>> getClientTokenRequestHeader() async {
//     final Map<String, String> _headers = {
//       REQUEST_HEADER_CLIENT_ID: MembershipConstants.clientID,
//       REQUEST_HEADER_SECRET_KEY: MembershipConstants.secretKey,
//     };
//
//     return _headers;
//   }
//
//   Future<Map<String, String>> getRequestHeader() async {
//     final String _clientToken = await _getClientToken();
//     final Map<String, String> _headers = {
//       REQUEST_HEADER_CLIENT_ID: MembershipConstants.clientID,
//       TokenHelper.SHARED_PREFERENCE_KEY_CLIENT_TOKEN: _clientToken,
//     };
//
//     return _headers;
//   }
//
//   Future<Map<String, String>> getRequestHeaderWithAccessToken() async {
//     String? _clientToken = TokenHelper.shared.getClientToken();
//
//     if (_clientToken == null || _clientToken.isEmpty)
//       _clientToken = await _getClientToken();
//
//     final String _accessToken = await TokenHelper.shared.getAccessToken() ?? '';
//     final Map<String, String> _headers = {
//       REQUEST_HEADER_CLIENT_ID: MembershipConstants.clientID,
//       TokenHelper.SHARED_PREFERENCE_KEY_CLIENT_TOKEN: _clientToken,
//       TokenHelper.SHARED_PREFERENCE_KEY_ACCESS_TOKEN: 'bearer $_accessToken',
//     };
//
//     return _headers;
//   }
//
//   Future<Response> makeRequestToMembershipApi({
//     required RequestMethods requestMethod,
//     required MembershipPaths path,
//     required Map<String, String> headers,
//     Map<String, dynamic>? body,
//     MembershipPathsOptions? options,
//     bool withFiles = false,
//     Map<String, Uint8List>? files,
//   }) async {
//     final Response _response = requestMethod == RequestMethods.get
//         ? await HttpHelper.shared.makeGetRequest(
//       requestProtocol: RequestProtocols.http,
//       domain: MembershipConstants.odooServerIP,
//       path: _getMembershipPath(path: path, options: options),
//       headers: headers,
//       body: body,
//     )
//         : withFiles
//         ? await HttpHelper.shared.makePostRequestWithFiles(
//       requestProtocol: RequestProtocols.http,
//       domain: MembershipConstants.odooServerIP,
//       path: _getMembershipPath(path: path, options: options),
//       headers: headers,
//       body: body,
//       files: files ?? {},
//     )
//         : await HttpHelper.shared.makePostRequest(
//       requestProtocol: RequestProtocols.http,
//       domain: MembershipConstants.odooServerIP,
//       path: _getMembershipPath(path: path, options: options),
//       headers: headers,
//       body: body,
//     );
//
//     return _response;
//   }
// }
