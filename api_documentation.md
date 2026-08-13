# WhizEats Pro - Complete API Documentation

> **Base URL**: `https://posapi.uvanij.com/api/`  
> **Authentication Header**: `Authorization: Bearer <posToken>` and `x-access-token: <posToken>`  
> **Central API Client Implementation**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart)  
> **API Constants File**: [`lib/core/constants/api_constants.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/core/constants/api_constants.dart)  
> **Last Updated**: August 13, 2026  

---

## Executive Overview

This document provides a comprehensive, production-grade technical specification of all RESTful API endpoints integrated into the **WhizEats Pro** Flutter application. Every endpoint documented below includes its route, HTTP method, service implementation file, usage location across providers/repositories/views, payload parameters, response data model, and detailed functional role within the application architecture.

---

## Table of Contents
1. [Module 1: Authentication & Session Management](#module-1-authentication--session-management)
2. [Module 2: Dashboard, Outlets & Table Management](#module-2-dashboard-outlets--table-management)
3. [Module 3: Menu Management & Product Catalog](#module-3-menu-management--product-catalog)
4. [Module 4: Order Taking, KOT & Cart Engine](#module-4-order-taking-kot--cart-engine)
5. [Module 5: Billing, Tax & Payment Processing](#module-5-billing-tax--payment-processing)
6. [Module 6: Offline Data Synchronization Engine](#module-6-offline-data-synchronization-engine)

---

## Module 1: Authentication & Session Management

### 1.1 Authenticate User Credentials
- **Endpoint Route**: `User/authenticate`
- **Full URL**: `https://posapi.uvanij.com/api/User/authenticate`
- **HTTP Method**: `POST`
- **Constant Identifier**: `ApiConstants.auth` ([`api_constants.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/core/constants/api_constants.dart#L11))
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L63) (`apiRequestHttpRawBody`)
- **Usage / Calling Files**:
  - Provider: [`lib/presentation/view_models/providers/auth_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/auth_provider.dart#L121) (`login()`)
  - Views: [`lib/presentation/views/auth/login_view.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/auth/login_view.dart), [`lib/presentation/views/auth/widgets/email_form_widget.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/auth/widgets/email_form_widget.dart)
- **Purpose**: `/User/authenticate` – Validates user credentials, returns bearer JWT token, user profile metadata, and assigned outlet location ID.
- **Request Body**:
  ```json
  {
    "userId": "username_or_email",
    "password": "user_password",
    "companyCode": "",
    "connectionString": "",
    "url": ""
  }
  ```
- **Response Model**: `AuthApiResModel` ([`lib/data/models/auth_api_res_model.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/models/auth_api_res_model.dart))
- **Functional Description**: Authenticates the staff/waiter login. Upon successful verification, the response contains `posToken` (saved to local Hive storage for subsequent API requests), user details (`userId`, `userName`, `companySiteUrl`), and `locationId` (stored as the active `outletId`).

---

## Module 2: Dashboard, Outlets & Table Management

### 2.1 Get Order Channel Types
- **Endpoint Route**: `Setting/GetOrderChannelTypes`
- **Full URL**: `https://posapi.uvanij.com/api/Setting/GetOrderChannelTypes`
- **HTTP Method**: `POST`
- **Constant Identifier**: `ApiConstants.getOrderChannelTypes` ([`api_constants.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/core/constants/api_constants.dart#L31))
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L189) (`getOrderChannelTypes()`)
- **Usage / Calling Files**:
  - Provider: [`lib/presentation/view_models/providers/table_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/table_provider.dart) (`loadOrderChannelTypes()`)
  - View: [`lib/presentation/views/dashboard/dashboard_view.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/dashboard/dashboard_view.dart)
- **Purpose**: `/Setting/GetOrderChannelTypes` – Fetches available dining/order channels (e.g., Table, Takeaway, Room Service, Delivery) for a company.
- **Request Body**:
  ```json
  {
    "companyId": 18
  }
  ```
- **Response Model**: `OrderChannelTypesModel` ([`lib/data/models/order_channel_types_model.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/models/order_channel_types_model.dart))
- **Functional Description**: Retrieves configured channel types to render dynamic tab headers on the Dashboard view.

---

### 2.2 Get Tables & Order Channels By Outlet & Type
- **Endpoint Route**: `Setting/OrderChannelListByType`
- **Full URL**: `https://posapi.uvanij.com/api/Setting/OrderChannelListByType`
- **HTTP Method**: `POST`
- **Constant Identifier**: `ApiConstants.getTablesByOutlet` ([`api_constants.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/core/constants/api_constants.dart#L17))
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L293) (`getOrderChannelListByType()`, `getTablesByOutlet()`, `getTablesByOutletEnhanced()`)
- **Repository Implementation File**: [`lib/data/repositories/table_repository.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/repositories/table_repository.dart#L11) (`fetchTablesFromOrderChannelAPI()`)
- **Usage / Calling Files**:
  - Repository: [`lib/data/repositories/table_repository.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/repositories/table_repository.dart)
  - Provider: [`lib/presentation/view_models/providers/table_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/table_provider.dart#L100) (`fetchTables()`, `loadTables()`)
  - Views: [`lib/presentation/views/dashboard/dashboard_view.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/dashboard/dashboard_view.dart), [`lib/presentation/views/dashboard/widgets/enhanced_table_card.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/dashboard/widgets/enhanced_table_card.dart)
- **Purpose**: `/Setting/OrderChannelListByType` – Fetches the list of tables/dining channels for an outlet, including table seating capacity and active order status.
- **Request Body**:
  ```json
  {
    "orderChanelType": "Table",
    "outletId": 10080
  }
  ```
- **Response Model**: `OrderChannelListApiResponseModel` ([`lib/data/models/order_channel_list_api_response_model.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/models/order_channel_list_api_response_model.dart))
- **Functional Description**: Serves as the backbone of table management on the dashboard. Returns each table's ID (`orderChannelId`), name, capacity, and active order array (`orderList`) containing order ID, order number, and billing status (`isBilled`).

---

### 2.3 Save / Create Order Head
- **Endpoint Route**: `Order/saveOrderHead`
- **Full URL**: `https://posapi.uvanij.com/api/Order/saveOrderHead`
- **HTTP Method**: `POST`
- **Constant Identifier**: `ApiConstants.createOrderHead` ([`api_constants.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/core/constants/api_constants.dart#L21))
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L228) (`saveOrderHead()`, `createOrderHead()`)
- **Usage / Calling Files**:
  - Providers: [`lib/presentation/view_models/providers/table_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/table_provider.dart#L250) (`occupyTable()`), [`lib/presentation/view_models/providers/animated_cart_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/animated_cart_provider.dart#L300) (`createOrderHead()`), [`lib/presentation/view_models/providers/order_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/order_provider.dart)
  - Views: [`lib/presentation/views/dashboard/widgets/table_action_dialogs.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/dashboard/widgets/table_action_dialogs.dart), [`lib/presentation/views/order_taking/cart/cart_view.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/order_taking/cart/cart_view.dart)
- **Purpose**: `/Order/saveOrderHead` – Initializes a new order header for a table or takeaway channel, changing table status to Occupied and returning a generated `orderId`.
- **Request Body**:
  ```json
  {
    "orderChannelId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "waiterId": "cceb307f-2f01-4e0e-8f28-e07ba8e941ac",
    "customerName": "Guest Table 5",
    "outletId": 10080,
    "userId": "user_123",
    "custPhoneNo": "9876543210",
    "totalAdult": 2,
    "totalChild": 0,
    "custEmailId": ""
  }
  ```
- **Response Model**: `CreateOrderHeadApiResModel` ([`lib/data/models/create_order_head_api_res_model.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/models/create_order_head_api_res_model.dart))
- **Functional Description**: Invoked when occupying a table or starting a new order. Creates an entry in the backend order head table and generates an `orderId` needed to append KOT items and generate bills.

---

### 2.4 Get Running Table Orders
- **Endpoint Route**: `Order/getRunningTable`
- **Full URL**: `https://posapi.uvanij.com/api/Order/getRunningTable`
- **HTTP Method**: `POST`
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L347) (`getRunningTable()`)
- **Usage / Calling Files**:
  - Providers: [`lib/presentation/view_models/providers/table_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/table_provider.dart) (`getRunningTableData()`), [`lib/presentation/view_models/providers/orders_management_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/orders_management_provider.dart)
  - Views: [`lib/presentation/views/dashboard/dashboard_view.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/dashboard/dashboard_view.dart), [`lib/presentation/views/dashboard/widgets/multi_order_management_dialog.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/dashboard/widgets/multi_order_management_dialog.dart), [`lib/presentation/views/orders/orders_management_view.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/orders/orders_management_view.dart)
- **Purpose**: `/Order/getRunningTable` – Retrieves active/running orders associated with a given table ID.
- **Request Body**:
  ```json
  {
    "searchString": "",
    "outletId": 10080,
    "orderChannelId": "table_guid_id",
    "isDesc": true
  }
  ```
- **Response Model**: `Map<String, dynamic>` (Raw JSON containing running order array)
- **Functional Description**: Supports multi-order tracking per table, allowing waiters to view running orders on occupied tables.

---

### 2.5 Update Order Head Status
- **Endpoint Route**: `Order/UpdateOrderHeadStatus`
- **Full URL**: `https://posapi.uvanij.com/api/Order/UpdateOrderHeadStatus`
- **HTTP Method**: `POST`
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L433) (`updateOrderHeadStatus()`)
- **Usage / Calling Files**:
  - Providers: [`lib/presentation/view_models/providers/table_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/table_provider.dart) (`updateTableStatus()`, `clearTable()`), [`lib/presentation/view_models/providers/orders_management_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/orders_management_provider.dart) (`updateOrderStatus()`)
  - Views: [`lib/presentation/views/dashboard/widgets/table_action_dialogs.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/dashboard/widgets/table_action_dialogs.dart), [`lib/presentation/views/dashboard/widgets/multi_order_management_dialog.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/dashboard/widgets/multi_order_management_dialog.dart)
- **Purpose**: `/Order/UpdateOrderHeadStatus` – Updates the order status (Occupied, Billed, Settled, Vacated, Cancelled).
- **Request Body**:
  ```json
  {
    "companyId": 18,
    "orderHeadId": "order_guid_id",
    "statusId": 7,
    "userId": "user_guid_id"
  }
  ```
- **Response Model**: `Map<String, dynamic>` (Status update result map)
- **Functional Description**: Transitions order states across the table lifecycle (e.g. status ID 6 = Occupied, status ID 7 = Settled/Vacated).

---

## Module 3: Menu Management & Product Catalog

### 3.1 Get All Product Categories
- **Endpoint Route**: `product/GetAllProductCategory`
- **Full URL**: `https://posapi.uvanij.com/api/product/GetAllProductCategory`
- **HTTP Method**: `POST`
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L805) (`getAllProductCategories()`)
- **Usage / Calling Files**:
  - Provider: [`lib/presentation/view_models/providers/menu_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/menu_provider.dart#L80) (`fetchCategories()`)
  - View: [`lib/presentation/views/menu_management/menu_view.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/menu_management/menu_view.dart)
- **Purpose**: `/product/GetAllProductCategory` – Fetches food categories (Appetizers, Main Course, Drinks, Desserts) for an outlet.
- **Request Body**:
  ```json
  {
    "outletId": 10080
  }
  ```
- **Response Model**: Category list JSON response
- **Functional Description**: Dynamically populates menu category filter tabs in the order taking view.

---

### 3.2 Get Item / Product Search
- **Endpoint Route**: `Product/GetItemSearch`
- **Full URL**: `https://posapi.uvanij.com/api/Product/GetItemSearch`
- **HTTP Method**: `POST`
- **Constant Identifier**: `ApiConstants.getItemSearch` ([`api_constants.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/core/constants/api_constants.dart#L28))
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L63) (`apiRequestHttpRawBody`)
- **Usage / Calling Files**:
  - Provider: [`lib/presentation/view_models/providers/menu_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/menu_provider.dart#L120) (`fetchMenuItems()`, `searchProducts()`)
  - Views: [`lib/presentation/views/menu_management/menu_view.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/menu_management/menu_view.dart), [`lib/presentation/views/menu_management/widgets/menu_grid.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/menu_management/widgets/menu_grid.dart)
- **Purpose**: `/Product/GetItemSearch` – Searches and retrieves menu items/dishes by category or keyword.
- **Request Body**:
  ```json
  {
    "outletId": 10080,
    "categoryId": 0,
    "searchKey": ""
  }
  ```
- **Response Model**: Product list JSON array (Item ID, Name, Price, Category ID, Image URL)
- **Functional Description**: Fetches products to render the menu grid in order taking screens.

---

### 3.3 Get Customer Wishlist Items
- **Endpoint Route**: `frontend/GetCustomerWishItems`
- **Full URL**: `https://posapi.uvanij.com/api/frontend/GetCustomerWishItems`
- **HTTP Method**: `POST`
- **Service Implementation File**: [`lib/data/repositories/wishlist_repository.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/repositories/wishlist_repository.dart#L9) (`getCustomerWishItems()`)
- **Usage / Calling Files**:
  - Repository: [`lib/data/repositories/wishlist_repository.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/repositories/wishlist_repository.dart)
- **Purpose**: `/frontend/GetCustomerWishItems` – Fetches saved customer favorite/wishlist food items.
- **Request Body**:
  ```json
  {
    "wishListCategoryId": 237,
    "customerId": 300,
    "companyId": 112
  }
  ```
- **Response Model**: `WishListApiResModel` ([`lib/data/models/wishlist_api_res_model.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/models/wishlist_api_res_model.dart))
- **Functional Description**: Loads customer favorite items for quick ordering.

---

## Module 4: Order Taking, KOT & Cart Engine

### 4.1 Create KOT With Order Details
- **Endpoint Route**: `Order/CreateKotWithOrderDetails`
- **Full URL**: `https://posapi.uvanij.com/api/Order/CreateKotWithOrderDetails`
- **HTTP Method**: `POST`
- **Constant Identifier**: `ApiConstants.createKotWithOrderDetails` ([`api_constants.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/core/constants/api_constants.dart#L24))
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L972) (`createKotWithOrderDetails()`)
- **Usage / Calling Files**:
  - Provider: [`lib/presentation/view_models/providers/animated_cart_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/animated_cart_provider.dart#L350) (`generateKOT()`)
  - Views: [`lib/presentation/views/order_taking/cart/cart_view.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/order_taking/cart/cart_view.dart), [`lib/presentation/views/order_taking/cart/widgets/kot_pdf_viewer_dialog.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/order_taking/cart/widgets/kot_pdf_viewer_dialog.dart)
- **Purpose**: `/Order/CreateKotWithOrderDetails` – Generates a Kitchen Order Ticket (KOT) and attaches line items to an active order ID.
- **Request Body**:
  ```json
  {
    "userId": "user_guid_id",
    "outletId": 10080,
    "orderId": "order_guid_id",
    "kotNote": "Less spicy, extra cheese",
    "orderDetails": [
      {
        "itemId": "item_guid_1",
        "itemName": "Paneer Butter Masala",
        "quantity": 2,
        "rate": 250.0,
        "amount": 500.0,
        "specialInstruction": "Make it medium spicy"
      }
    ]
  }
  ```
- **Response Model**: `CreateKotWithOrderDetailsApiResModel` ([`lib/data/models/create_kot_with_order_details_api_res_model.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/models/create_kot_with_order_details_api_res_model.dart))
- **Functional Description**: Dispatches items from the cart to kitchen printers, updates order status, and generates a printable KOT voucher.

---

### 4.2 Get Order Details By ID
- **Endpoint Route**: `Order/getOrderDetailById`
- **Full URL**: `https://posapi.uvanij.com/api/Order/getOrderDetailById`
- **HTTP Method**: `POST`
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L393) (`getOrderDetailById()`)
- **Usage / Calling Files**:
  - Providers: [`lib/presentation/view_models/providers/animated_cart_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/animated_cart_provider.dart#L420) (`loadOrderDetails()`), [`lib/presentation/view_models/providers/orders_management_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/orders_management_provider.dart#L150) (`fetchOrderDetails()`)
  - Views: [`lib/presentation/views/order_taking/cart/cart_view.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/order_taking/cart/cart_view.dart), [`lib/presentation/views/orders/widgets/order_detail_view.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/orders/widgets/order_detail_view.dart)
- **Purpose**: `/Order/getOrderDetailById` – Fetches complete order item details for editing or review.
- **Request Body**:
  ```json
  {
    "orderId": "order_guid_id"
  }
  ```
- **Response Model**: `OrderDetailApiResponseModel` ([`lib/data/models/order_detail_api_response_model.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/models/order_detail_api_response_model.dart))
- **Functional Description**: Loads existing order line items into the cart view when an occupied table is reopened.

---

## Module 5: Billing, Tax & Payment Processing

### 5.1 Get All Taxes
- **Endpoint Route**: `Order/getTaxDt`
- **Full URL**: `https://posapi.uvanij.com/api/Order/getTaxDt`
- **HTTP Method**: `POST`
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L841) (`getAllTaxes()`)
- **Usage / Calling Files**:
  - Provider: [`lib/presentation/view_models/providers/tax_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/tax_provider.dart#L45) (`fetchTaxes()`)
  - View: [`lib/presentation/views/billing/widgets/generate_bill_summary_dialog.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/billing/widgets/generate_bill_summary_dialog.dart)
- **Purpose**: `/Order/getTaxDt` – Retrieves tax configuration rates (GST 5%, CGST 2.5%, SGST 2.5%) for a company.
- **Request Body**:
  ```json
  {
    "companyId": 18
  }
  ```
- **Response Model**: Tax details JSON response
- **Functional Description**: Calculates GST and tax breakdowns during bill summary generation.

---

### 5.2 Get Payment Modes
- **Endpoint Route**: `Order/GetPaymentMode`
- **Full URL**: `https://posapi.uvanij.com/api/Order/GetPaymentMode`
- **HTTP Method**: `POST`
- **Constant Identifier**: `ApiConstants.getPaymentModes` ([`api_constants.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/core/constants/api_constants.dart#L14))
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L877) (`getAllPaymentModes()`)
- **Usage / Calling Files**:
  - Provider: [`lib/presentation/view_models/providers/billing_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/billing_provider.dart#L50) (`loadPaymentModes()`)
  - View: [`lib/presentation/views/billing/widgets/generate_bill_summary_dialog.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/billing/widgets/generate_bill_summary_dialog.dart)
- **Purpose**: `/Order/GetPaymentMode` – Fetches available payment methods (Cash, Card, UPI, QR Code, Online).
- **Request Body**: `{}` (Empty JSON map as required by endpoint)
- **Response Model**: `PaymentModeApiResModel` ([`lib/data/models/payment_mode_api_res_model.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/models/payment_mode_api_res_model.dart))
- **Functional Description**: Renders full-width selectable payment mode chips in the bill summary popup dialog.

---

### 5.3 Get Order Detail For Bill
- **Endpoint Route**: `Order/GetOrderDetalForBill`
- **Full URL**: `https://posapi.uvanij.com/api/Order/GetOrderDetalForBill`
- **HTTP Method**: `POST`
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L1033) (`getOrderDetailForBill()`)
- **Usage / Calling Files**:
  - Provider: [`lib/presentation/view_models/providers/billing_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/billing_provider.dart#L80) (`loadOrderDetailForBill()`)
  - View: [`lib/presentation/views/billing/widgets/generate_bill_summary_dialog.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/billing/widgets/generate_bill_summary_dialog.dart)
- **Purpose**: `/Order/GetOrderDetalForBill` – Fetches order breakdown specifically structured for bill generation.
- **Request Body**:
  ```json
  {
    "orderId": "order_guid_id"
  }
  ```
- **Response Model**: `GetOrderDetailForBillResponse` ([`lib/data/models/bill_generation_models.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/models/bill_generation_models.dart))
- **Functional Description**: Supplies item totals, subtotal, discount, and tax calculations for the bill preview modal.

---

### 5.4 Get Customer By Mobile Number
- **Endpoint Route**: `Order/getCustomerByMobileNo`
- **Full URL**: `https://posapi.uvanij.com/api/Order/getCustomerByMobileNo`
- **HTTP Method**: `POST`
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L1068) (`getCustomerByMobileNo()`)
- **Usage / Calling Files**:
  - Provider: [`lib/presentation/view_models/providers/billing_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/billing_provider.dart#L110) (`fetchCustomerByPhone()`)
  - View: [`lib/presentation/views/billing/widgets/generate_bill_summary_dialog.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/billing/widgets/generate_bill_summary_dialog.dart)
- **Purpose**: `/Order/getCustomerByMobileNo` – Searches customer profiles by 10-digit phone number.
- **Request Body**:
  ```json
  {
    "contactNo": "9876543210"
  }
  ```
- **Response Model**: `CustomerByMobileResponse` ([`lib/data/models/bill_generation_models.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/models/bill_generation_models.dart))
- **Functional Description**: Auto-fills customer profile info when entering a 10-digit mobile number during billing.

---

### 5.5 Create Bill
- **Endpoint Route**: `Order/CreateBill`
- **Full URL**: `https://posapi.uvanij.com/api/Order/CreateBill`
- **HTTP Method**: `POST`
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L1104) (`createBill()`)
- **Usage / Calling Files**:
  - Provider: [`lib/presentation/view_models/providers/billing_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/billing_provider.dart#L140) (`generateBill()`)
  - View: [`lib/presentation/views/billing/widgets/generate_bill_summary_dialog.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/billing/widgets/generate_bill_summary_dialog.dart)
- **Purpose**: `/Order/CreateBill` – Generates a final bill record and produces a printable PDF receipt.
- **Request Body**:
  ```json
  {
    "orderId": "order_guid_id",
    "subTotal": 500.0,
    "taxAmount": 25.0,
    "discountAmount": 0.0,
    "grandTotal": 525.0,
    "paymentModeId": 1,
    "customerPhone": "9876543210",
    "userId": "user_guid_id"
  }
  ```
- **Response Model**: `CreateBillResponse` ([`lib/data/models/bill_generation_models.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/models/bill_generation_models.dart))
- **Functional Description**: Saves the bill, returns `billId` and printable bill details for `BillPDFViewerDialog`.

---

### 5.6 Save Payment
- **Endpoint Route**: `Order/SavePayment`
- **Full URL**: `https://posapi.uvanij.com/api/Order/SavePayment`
- **HTTP Method**: `POST`
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L1139) (`savePayment()`)
- **Usage / Calling Files**:
  - Provider: [`lib/presentation/view_models/providers/billing_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/billing_provider.dart#L190) (`processPayment()`)
  - View: [`lib/presentation/views/payment/payment_page.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/payment/payment_page.dart)
- **Purpose**: `/Order/SavePayment` – Records payment transaction and settles bill/table.
- **Request Body**:
  ```json
  {
    "billId": "bill_guid_id",
    "paymentModeId": 1,
    "amountPaid": 525.0,
    "transactionReference": "TXN987654",
    "userId": "user_guid_id"
  }
  ```
- **Response Model**: `SavePaymentResponse` ([`lib/data/models/bill_generation_models.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/models/bill_generation_models.dart))
- **Functional Description**: Finalizes bill settlement, updating order status to Paid and table status to Settled/Available.

---

### 5.7 Get Bill Detail By Bill ID
- **Endpoint Route**: `Order/getBillDetailByBillId`
- **Full URL**: `https://posapi.uvanij.com/api/Order/getBillDetailByBillId`
- **HTTP Method**: `POST`
- **Service Implementation File**: [`lib/services/api_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/api_service.dart#L1175) (`getBillDetailByBillId()`)
- **Usage / Calling Files**:
  - Provider: [`lib/presentation/view_models/providers/billing_provider.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/view_models/providers/billing_provider.dart#L230) (`fetchBillDetail()`)
  - Views: [`lib/presentation/views/billing/widgets/bill_success_dialog.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/billing/widgets/bill_success_dialog.dart), [`lib/presentation/views/billing/widgets/bill_pdf_viewer_dialog.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/presentation/views/billing/widgets/bill_pdf_viewer_dialog.dart)
- **Purpose**: `/Order/getBillDetailByBillId` – Fetches complete bill details by `billId` for reprint or verification.
- **Request Body**:
  ```json
  {
    "billId": "bill_guid_id"
  }
  ```
- **Response Model**: `BillDetailsResponse` ([`lib/data/models/bill_details_response.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/data/models/bill_details_response.dart))
- **Functional Description**: Retrieves structured invoice items, tax lines, and payment status for receipt printing.

---

## Module 6: Offline Data Synchronization Engine

### 6.1 Sync Tables & Orders (Background Queue)
- **Endpoint Routes**: `tables` (`$baseUrl/tables`), `orders` (`$baseUrl/orders`)
- **Full URL**: `https://your-api-server.com/api/tables` & `https://your-api-server.com/api/orders`
- **HTTP Method**: `POST`
- **Service Implementation File**: [`lib/services/sync_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/sync_service.dart#L38) (`_syncTables()`, `_syncOrders()`, `syncAllData()`)
- **Usage / Calling Files**:
  - Service: [`lib/services/sync_service.dart`](file:///c:/Flutter%20Projects/restaurant_pos_system/lib/services/sync_service.dart)
- **Purpose**: Syncs offline Hive storage items to the backend when internet connectivity is re-established.
- **Functional Description**: Scans unsynced Hive records (`table.synced == false`, `order.synced == false`) and pushes them to the server via background batch requests.

---

## Summary Matrix of All Endpoints

| # | Endpoint / Route | Method | Purpose | Service File | Provider / Repository | View / UI Component |
|---|---|---|---|---|---|---|
| 1 | `User/authenticate` | `POST` | User login & token auth | `api_service.dart` | `auth_provider.dart` | `login_view.dart` |
| 2 | `Setting/GetOrderChannelTypes` | `POST` | Get order channel types | `api_service.dart` | `table_provider.dart` | `dashboard_view.dart` |
| 3 | `Setting/OrderChannelListByType` | `POST` | Get tables by outlet & type | `api_service.dart`, `table_repository.dart` | `table_provider.dart` | `dashboard_view.dart`, `enhanced_table_card.dart` |
| 4 | `Order/saveOrderHead` | `POST` | Create new order header | `api_service.dart` | `table_provider.dart`, `animated_cart_provider.dart` | `table_action_dialogs.dart`, `cart_view.dart` |
| 5 | `Order/getRunningTable` | `POST` | Get running table orders | `api_service.dart` | `table_provider.dart`, `orders_management_provider.dart` | `multi_order_management_dialog.dart`, `orders_management_view.dart` |
| 6 | `Order/UpdateOrderHeadStatus` | `POST` | Update order/table status | `api_service.dart` | `table_provider.dart`, `orders_management_provider.dart` | `table_action_dialogs.dart` |
| 7 | `product/GetAllProductCategory` | `POST` | Get menu categories | `api_service.dart` | `menu_provider.dart` | `menu_view.dart` |
| 8 | `Product/GetItemSearch` | `POST` | Search & fetch menu items | `api_service.dart` | `menu_provider.dart` | `menu_view.dart`, `menu_grid.dart` |
| 9 | `frontend/GetCustomerWishItems` | `POST` | Get customer wishlist items | `wishlist_repository.dart` | `wishlist_repository.dart` | Wishlist view |
| 10 | `Order/CreateKotWithOrderDetails` | `POST` | Create KOT with items | `api_service.dart` | `animated_cart_provider.dart` | `cart_view.dart`, `kot_pdf_viewer_dialog.dart` |
| 11 | `Order/getOrderDetailById` | `POST` | Get detailed order items | `api_service.dart` | `animated_cart_provider.dart`, `orders_management_provider.dart` | `cart_view.dart`, `order_detail_view.dart` |
| 12 | `Order/getTaxDt` | `POST` | Get company tax rates | `api_service.dart` | `tax_provider.dart` | `generate_bill_summary_dialog.dart` |
| 13 | `Order/GetPaymentMode` | `POST` | Get payment modes | `api_service.dart` | `billing_provider.dart` | `generate_bill_summary_dialog.dart` |
| 14 | `Order/GetOrderDetalForBill` | `POST` | Get order details for bill | `api_service.dart` | `billing_provider.dart` | `generate_bill_summary_dialog.dart` |
| 15 | `Order/getCustomerByMobileNo` | `POST` | Customer phone lookup | `api_service.dart` | `billing_provider.dart` | `generate_bill_summary_dialog.dart` |
| 16 | `Order/CreateBill` | `POST` | Generate official bill | `api_service.dart` | `billing_provider.dart` | `generate_bill_summary_dialog.dart` |
| 17 | `Order/SavePayment` | `POST` | Record payment settlement | `api_service.dart` | `billing_provider.dart` | `payment_page.dart` |
| 18 | `Order/getBillDetailByBillId` | `POST` | Get bill receipt details | `api_service.dart` | `billing_provider.dart` | `bill_success_dialog.dart`, `bill_pdf_viewer_dialog.dart` |
| 19 | `$baseUrl/tables` & `orders` | `POST` | Offline sync queue | `sync_service.dart` | `sync_service.dart` | Background Sync Task |

