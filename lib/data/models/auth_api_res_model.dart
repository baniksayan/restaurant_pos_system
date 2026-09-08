class AuthApiResModel {
  Data? data;
  String? message;
  bool? isSuccess;
  int? statusCode;

  AuthApiResModel({this.data, this.message, this.isSuccess, this.statusCode});

  AuthApiResModel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    message = json['message'];
    isSuccess = json['isSuccess'];
    statusCode = json['statusCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['message'] = message;
    data['isSuccess'] = isSuccess;
    data['statusCode'] = statusCode;
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

  Data({
    this.userDetails,
    this.roles,
    this.permissionModuleList,
    this.permissionMenuList,
    this.bindParentMenu,
    this.bindMenu,
    this.posToken,
    this.location,
  });

  Data.fromJson(Map<String, dynamic> json) {
    userDetails =
        json['userDetails'] != null
            ? UserDetails.fromJson(json['userDetails'])
            : null;
    if (json['roles'] != null) {
      roles = <Roles>[];
      json['roles'].forEach((v) {
        roles!.add(Roles.fromJson(v));
      });
    }
    if (json['permissionModuleList'] != null) {
      permissionModuleList = <PermissionModuleList>[];
      json['permissionModuleList'].forEach((v) {
        permissionModuleList!.add(PermissionModuleList.fromJson(v));
      });
    }
    if (json['permissionMenuList'] != null) {
      permissionMenuList = <PermissionMenuList>[];
      json['permissionMenuList'].forEach((v) {
        permissionMenuList!.add(PermissionMenuList.fromJson(v));
      });
    }
    if (json['bindParentMenu'] != null) {
      bindParentMenu = <BindParentMenu>[];
      json['bindParentMenu'].forEach((v) {
        bindParentMenu!.add(BindParentMenu.fromJson(v));
      });
    }
    if (json['bindMenu'] != null) {
      bindMenu = <BindMenu>[];
      json['bindMenu'].forEach((v) {
        bindMenu!.add(BindMenu.fromJson(v));
      });
    }
    posToken = json['posToken'];
    location =
        json['location'] != null
            ? Location.fromJson(json['location'])
            : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (userDetails != null) {
      data['userDetails'] = userDetails!.toJson();
    }
    if (roles != null) {
      data['roles'] = roles!.map((v) => v.toJson()).toList();
    }
    if (permissionModuleList != null) {
      data['permissionModuleList'] =
          permissionModuleList!.map((v) => v.toJson()).toList();
    }
    if (permissionMenuList != null) {
      data['permissionMenuList'] =
          permissionMenuList!.map((v) => v.toJson()).toList();
    }
    if (bindParentMenu != null) {
      data['bindParentMenu'] =
          bindParentMenu!.map((v) => v.toJson()).toList();
    }
    if (bindMenu != null) {
      data['bindMenu'] = bindMenu!.map((v) => v.toJson()).toList();
    }
    data['posToken'] = posToken;
    if (location != null) {
      data['location'] = location!.toJson();
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
  String? companySiteUrl;

  UserDetails({
    this.userId,
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
    this.apiKey,
    this.companySiteUrl,
  });

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
    companySiteUrl = json['companySiteUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['companyId'] = companyId;
    data['email'] = email;
    data['userName'] = userName;
    data['password'] = password;
    data['firstName'] = firstName;
    data['middleName'] = middleName;
    data['lastName'] = lastName;
    data['address'] = address;
    data['address2'] = address2;
    data['city'] = city;
    data['state'] = state;
    data['stateCode'] = stateCode;
    data['country'] = country;
    data['countryCode'] = countryCode;
    data['postalCode'] = postalCode;
    data['phone'] = phone;
    data['imagePath'] = imagePath;
    data['isActive'] = isActive;
    data['createdDate'] = createdDate;
    data['createdBy'] = createdBy;
    data['isCustomer'] = isCustomer;
    data['phoneCode'] = phoneCode;
    data['userPhoneCountryCode'] = userPhoneCountryCode;
    data['apiKey'] = apiKey;
    data['companySiteUrl'] = companySiteUrl;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['roleMappingId'] = roleMappingId;
    data['roleId'] = roleId;
    data['roleName'] = roleName;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['moduleName'] = moduleName;
    data['parentMenuId'] = parentMenuId;
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

  PermissionMenuList({
    this.menuId,
    this.menuName,
    this.isActive,
    this.displayOrder,
    this.moduleName,
    this.url,
    this.parentMenuId,
  });

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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['menuId'] = menuId;
    data['menuName'] = menuName;
    data['isActive'] = isActive;
    data['displayOrder'] = displayOrder;
    data['moduleName'] = moduleName;
    data['url'] = url;
    data['parentMenuId'] = parentMenuId;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['parentMenuId'] = parentMenuId;
    data['parentMenu'] = parentMenu;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['menuId'] = menuId;
    data['menuName'] = menuName;
    return data;
  }
}

class Location {
  int? locationId;
  String? locationName;
  String? locationType;
  String? locAddress;

  Location({
    this.locationId,
    this.locationName,
    this.locationType,
    this.locAddress,
  });

  Location.fromJson(Map<String, dynamic> json) {
    locationId = json['locationId'];
    locationName = json['locationName'];
    locationType = json['locationType'];
    locAddress = json['locAddress'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['locationId'] = locationId;
    data['locationName'] = locationName;
    data['locationType'] = locationType;
    data['locAddress'] = locAddress;
    return data;
  }
}
