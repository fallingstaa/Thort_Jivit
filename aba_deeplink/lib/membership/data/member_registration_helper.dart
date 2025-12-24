// import 'package:http/http.dart' show Response;
//
// import '../model/membership_registration_model.dart';
//
//
// class MembershipRegistrationHelper {
//   static final shared = MembershipRegistrationHelper();
//
//   Future<MembershipRegistrationResponse> registerForMembership(MembershipRegistrationRequestBody body) async {
//     final Map<String, String> _headers = await MembershipApiHelper.shared.getRequestHeader();
//
//     print('===Registering For Membership===');
//     final Response _response = await MembershipApiHelper.shared.makeRequestToMembershipApi(
//       requestMethod: RequestMethods.post,
//       path: MembershipPaths.register_for_membership,
//       headers: _headers,
//       body: body.toMap(),
//       withFiles: true,
//       files: body.toFiles(),
//     );
//
//     return MembershipRegistrationResponse.fromJson(
//       MembershipApiHelper.shared.responseToData(_response),
//       _response.statusCode,
//     );
//   }
// }
