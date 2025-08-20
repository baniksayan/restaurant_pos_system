class AuthApiResModel {
  Data? data;
  String? message;
  bool? isSuccess;
  int? statusCode;

  AuthApiResModel({this.data, this.message, this.isSuccess, this.statusCode});

  AuthApiResModel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    message = json['message'];
    isSuccess = json['isSuccess'];
    statusCode = json['statusCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['message'] = this.message;
    data['isSuccess'] = this.isSuccess;
    data['statusCode'] = this.statusCode;
    return data;
  }
}

class Data {
  UserDetails? userDetails;
  List<Roles>? roles;
  List<PermissionModuleList>? permissionModuleList;
  List<PermissionMenuList>? permissionMenuList;
  List<BindParentMenu>? bindParentMenu;
  List<BindMenu>? bindMenu;
  String? posToken;
  Location? location;

  Data(
      {this.userDetails,
      this.roles,
      this.permissionModuleList,
      this.permissionMenuList,
      this.bindParentMenu,
      this.bindMenu,
      this.posToken,
      this.location});

  Data.fromJson(Map<String, dynamic> json) {
    userDetails = json['userDetails'] != null
        ? new UserDetails.fromJson(json['userDetails'])
        : null;
    if (json['roles'] != null) {
      roles = <Roles>[];
      json['roles'].forEach((v) {
        roles!.add(new Roles.fromJson(v));
      });
    }
    if (json['permissionModuleList'] != null) {
      permissionModuleList = <PermissionModuleList>[];
      json['permissionModuleList'].forEach((v) {
        permissionModuleList!.add(new PermissionModuleList.fromJson(v));
      });
    }
    if (json['permissionMenuList'] != null) {
      permissionMenuList = <PermissionMenuList>[];
      json['permissionMenuList'].forEach((v) {
        permissionMenuList!.add(new PermissionMenuList.fromJson(v));
      });
    }
    if (json['bindParentMenu'] != null) {
      bindParentMenu = <BindParentMenu>[];
      json['bindParentMenu'].forEach((v) {
        bindParentMenu!.add(new BindParentMenu.fromJson(v));
      });
    }
    if (json['bindMenu'] != null) {
      bindMenu = <BindMenu>[];
      json['bindMenu'].forEach((v) {
        bindMenu!.add(new BindMenu.fromJson(v));
      });
    }
    posToken = json['posToken'];
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.userDetails != null) {
      data['userDetails'] = this.userDetails!.toJson();
    }
    if (this.roles != null) {
      data['roles'] = this.roles!.map((v) => v.toJson()).toList();
    }
    if (this.permissionModuleList != null) {
      data['permissionModuleList'] =
          this.permissionModuleList!.map((v) => v.toJson()).toList();
    }
    if (this.permissionMenuList != null) {
      data['permissionMenuList'] =
          this.permissionMenuList!.map((v) => v.toJson()).toList();
    }
    if (this.bindParentMenu != null) {
      data['bindParentMenu'] =
          this.bindParentMenu!.map((v) => v.toJson()).toList();
    }
    if (this.bindMenu != null) {
      data['bindMenu'] = this.bindMenu!.map((v) => v.toJson()).toList();
    }
    data['posToken'] = this.posToken;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    return data;
  }
}

class UserDetails {
  String? userId;
  int? companyId;
  String? email;
  String? userName;
  String? password;
  String? firstName;
  String? middleName;
  String? lastName;
  String? address;
  String? address2;
  String? city;
  String? state;
  String? stateCode;
  String? country;
  String? countryCode;
  String? postalCode;
  String? phone;
  String? imagePath;
  bool? isActive;
  String? createdDate;
  String? createdBy;
  bool? isCustomer;
  String? phoneCode;
  String? userPhoneCountryCode;
  String? apiKey;

  UserDetails(
      {this.userId,
      this.companyId,
      this.email,
      this.userName,
      this.password,
      this.firstName,
      this.middleName,
      this.lastName,
      this.address,
      this.address2,
      this.city,
      this.state,
      this.stateCode,
      this.country,
      this.countryCode,
      this.postalCode,
      this.phone,
      this.imagePath,
      this.isActive,
      this.createdDate,
      this.createdBy,
      this.isCustomer,
      this.phoneCode,
      this.userPhoneCountryCode,
      this.apiKey});

  UserDetails.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    companyId = json['companyId'];
    email = json['email'];
    userName = json['userName'];
    password = json['password'];
    firstName = json['firstName'];
    middleName = json['middleName'];
    lastName = json['lastName'];
    address = json['address'];
    address2 = json['address2'];
    city = json['city'];
    state = json['state'];
    stateCode = json['stateCode'];
    country = json['country'];
    countryCode = json['countryCode'];
    postalCode = json['postalCode'];
    phone = json['phone'];
    imagePath = json['imagePath'];
    isActive = json['isActive'];
    createdDate = json['createdDate'];
    createdBy = json['createdBy'];
    isCustomer = json['isCustomer'];
    phoneCode = json['phoneCode'];
    userPhoneCountryCode = json['userPhoneCountryCode'];
    apiKey = json['apiKey'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userId'] = this.userId;
    data['companyId'] = this.companyId;
    data['email'] = this.email;
    data['userName'] = this.userName;
    data['password'] = this.password;
    data['firstName'] = this.firstName;
    data['middleName'] = this.middleName;
    data['lastName'] = this.lastName;
    data['address'] = this.address;
    data['address2'] = this.address2;
    data['city'] = this.city;
    data['state'] = this.state;
    data['stateCode'] = this.stateCode;
    data['country'] = this.country;
    data['countryCode'] = this.countryCode;
    data['postalCode'] = this.postalCode;
    data['phone'] = this.phone;
    data['imagePath'] = this.imagePath;
    data['isActive'] = this.isActive;
    data['createdDate'] = this.createdDate;
    data['createdBy'] = this.createdBy;
    data['isCustomer'] = this.isCustomer;
    data['phoneCode'] = this.phoneCode;
    data['userPhoneCountryCode'] = this.userPhoneCountryCode;
    data['apiKey'] = this.apiKey;
    return data;
  }
}

class Roles {
  String? roleMappingId;
  String? roleId;
  String? roleName;

  Roles({this.roleMappingId, this.roleId, this.roleName});

  Roles.fromJson(Map<String, dynamic> json) {
    roleMappingId = json['roleMappingId'];
    roleId = json['roleId'];
    roleName = json['roleName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['roleMappingId'] = this.roleMappingId;
    data['roleId'] = this.roleId;
    data['roleName'] = this.roleName;
    return data;
  }
}

class PermissionModuleList {
  String? moduleName;
  int? parentMenuId;

  PermissionModuleList({this.moduleName, this.parentMenuId});

  PermissionModuleList.fromJson(Map<String, dynamic> json) {
    moduleName = json['moduleName'];
    parentMenuId = json['parentMenuId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['moduleName'] = this.moduleName;
    data['parentMenuId'] = this.parentMenuId;
    return data;
  }
}

class PermissionMenuList {
  int? menuId;
  String? menuName;
  bool? isActive;
  int? displayOrder;
  String? moduleName;
  String? url;
  int? parentMenuId;

  PermissionMenuList(
      {this.menuId,
      this.menuName,
      this.isActive,
      this.displayOrder,
      this.moduleName,
      this.url,
      this.parentMenuId});

  PermissionMenuList.fromJson(Map<String, dynamic> json) {
    menuId = json['menuId'];
    menuName = json['menuName'];
    isActive = json['isActive'];
    displayOrder = json['displayOrder'];
    moduleName = json['moduleName'];
    url = json['url'];
    parentMenuId = json['parentMenuId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['menuId'] = this.menuId;
    data['menuName'] = this.menuName;
    data['isActive'] = this.isActive;
    data['displayOrder'] = this.displayOrder;
    data['moduleName'] = this.moduleName;
    data['url'] = this.url;
    data['parentMenuId'] = this.parentMenuId;
    return data;
  }
}

class BindParentMenu {
  int? parentMenuId;
  String? parentMenu;

  BindParentMenu({this.parentMenuId, this.parentMenu});

  BindParentMenu.fromJson(Map<String, dynamic> json) {
    parentMenuId = json['parentMenuId'];
    parentMenu = json['parentMenu'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['parentMenuId'] = this.parentMenuId;
    data['parentMenu'] = this.parentMenu;
    return data;
  }
}

class BindMenu {
  int? menuId;
  String? menuName;

  BindMenu({this.menuId, this.menuName});

  BindMenu.fromJson(Map<String, dynamic> json) {
    menuId = json['menuId'];
    menuName = json['menuName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['menuId'] = this.menuId;
    data['menuName'] = this.menuName;
    return data;
  }
}

class Location {
  int? locationId;
  String? locationName;
  String? locationType;
  String? locAddress;

  Location(
      {this.locationId, this.locationName, this.locationType, this.locAddress});

  Location.fromJson(Map<String, dynamic> json) {
    locationId = json['locationId'];
    locationName = json['locationName'];
    locationType = json['locationType'];
    locAddress = json['locAddress'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['locationId'] = this.locationId;
    data['locationName'] = this.locationName;
    data['locationType'] = this.locationType;
    data['locAddress'] = this.locAddress;
    return data;
  }
}
