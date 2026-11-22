# Finverse Auth Flow

## 1. Api Authentication

### 1.1 Authenticate with Finverse API

`POST /auth/customer/token (client_id, client_secret)`

[See docs](https://docs.finverse.com/#be7bc090-0c7b-41f1-8472-3c0b980e4ed1)

Example response:
```json
{
    "access_token": "{customer_token}",
    "expires_in": 3600,
    "issued_at": "2026-11-11T18:05:55.000Z",
    "token_type": "Bearer"
}
```

## 2. Bank Authentication

### 2.1 Generate Finverse Link URL

`POST /link/token (customer_token, client_id, redirect_uri, state, user_id)`

[See docs](https://docs.finverse.com/#8a4e26e2-84e9-4ef0-ab6f-d7734d775991)

Example response:
```json
{
    "redirect_uri": "https://developer.prod.finverse.net/sink",
    "success": {
        "code": "03M75JR8QJ8BGJE3JGY03TFJ3T",
        "login_identity_id": "01M75JM18G1ZZ3HTYGH7N7SE3F",
        "state": "{{customer_app_id}}_stateparameter"
    }
}
```

### 2.2 Exchange Link code for Login Identity Token

`POST /auth/token (customer_token, cliend_id, code, redirect_uri)`

[See docs](https://docs.finverse.com/#eeb96d88-3ea8-4388-8272-ad339e91b631)

Example response:
```json
{
    "access_token": "{login_identity_token}",
    "expires_in": 3600,
    "issued_at": "2026-11-11T15:46:33.000Z",
    "login_identity_id": "01M75LKDKTR0H56338582F8HMG",
    "refresh_token": "{login_identity_refresh_token}",
    "token_type": "Bearer"
}
```

