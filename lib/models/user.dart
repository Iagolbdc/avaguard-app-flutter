class User {
  String userId;
  String email;
  String firstName;
  String lastName;
  String userType;

  User({
    required this.email,
    required this.userType,
    required this.firstName,
    required this.lastName,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        "email": email,
        "userType": userType,
        "firstName": firstName,
        "lastName": lastName,
        "userId": userId,
      };
}
