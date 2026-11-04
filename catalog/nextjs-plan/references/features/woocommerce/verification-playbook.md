# Verification Playbook

Copy-paste checks for a Next.js + WooCommerce stack. Replace `shop.local` and credentials. Run from the host; use `--resolve` so no DNS change is required.

```powershell
$base = "https://shop.local"
$resolve = "shop.local:443:127.0.0.1"
```

---

## 1. Routing

```powershell
curl.exe -k -sS -o NUL -w "home=%{http_code}`n"      --resolve $resolve "$base/"
curl.exe -k -sS -o NUL -w "products=%{http_code}`n"  --resolve $resolve "$base/products"
curl.exe -k -sS -o NUL -w "cart=%{http_code}`n"      --resolve $resolve "$base/cart"
curl.exe -k -sS -o NUL -w "graphql=%{http_code}`n"   --resolve $resolve "$base/graphql"
curl.exe -k -sS -o NUL -w "health=%{http_code}`n"    --resolve $resolve "$base/api/health"
```

Expect Next.js for `/`, `/products`, `/cart`; WordPress for `/graphql`, `/wp-admin`, `/my-account`, `/checkout`.

### Gateway callbacks

```powershell
# GET and POST, with and without trailing slash
curl.exe -k -sS -D - -o NUL --resolve $resolve "$base/wc-api/TestGateway/"
curl.exe -k -sS -D - -o NUL -X POST --resolve $resolve "$base/wc-api/TestGateway/"
```

Expect **307** and `Location: https://shop.local/checkout/?wc-api=TestGateway`. A `308` means `skipTrailingSlashRedirect` is missing.

`?wc-ajax=` must reach WordPress (a 400/403 without a nonce is fine; Next.js HTML is not):

```powershell
curl.exe -k -sS -D - -o NUL --resolve $resolve "$base/?wc-ajax=update_order_review"
```

An empty cart redirects `/checkout/` to `/cart/` with 302; populate the cart first before asserting checkout HTML.

### ZarinPal sandbox (random UUID merchant)

The ZarinPal plugin (`zarinpal-woocommerce-payment-gateway` 5.1.1) reads `merchantcode` and `sandbox` from `woocommerce_WC_ZPal_settings`. Sandbox mode talks to `https://sandbox.zarinpal.com/pg/v4/payment/` and never validates the merchant ID, so a generated UUID is enough to activate the gateway — no merchant contract required.

```powershell
# Enabled + sandbox + UUID merchant code
docker exec -u www-data wordpress wp eval '
$s = get_option("woocommerce_WC_ZPal_settings", []);
$s["enabled"] = "yes";
$s["sandbox"] = "yes";
$s["merchantcode"] = wp_generate_uuid4();
update_option("woocommerce_WC_ZPal_settings", $s);
echo json_encode($s) . "\n";
' --path=/var/www/html
```

Assert the sandbox handshake end-to-end (expects an `S...` authority and a `sandbox.zarinpal.com/pg/StartPay/` URL, never an "invalid merchant" error):

```powershell
docker exec -u www-data wordpress wp eval '
$z = get_option("woocommerce_WC_ZPal_settings");
try {
  $zp = new ZarinpalHelperClass($z["merchantcode"], true, "");
  $authority = $zp->requestPayment(10000, "https://shop.local/checkout/?wc-api=WC_ZPal", "sandbox check");
  echo "OK " . $zp->getRedirectUrl($authority) . "\n";
} catch (Exception $e) {
  echo "ERR " . $e->getMessage() . "\n";
}
' --path=/var/www/html
```

Verified 2026-10-28 on the local stack: UUID `merchantcode` + `sandbox=yes` returned `https://sandbox.zarinpal.com/pg/StartPay/S000...`.

---

## 2. GraphQL Catalog

```powershell
$body = @'
{"query":"{ products(first: 10) { nodes { __typename databaseId name slug ... on SimpleProduct { price stockStatus } ... on VariableProduct { price stockStatus variations { nodes { databaseId name price } } } productCategories { nodes { name slug } } } } productCategories(first: 10) { nodes { name slug count } } }"}
'@
Invoke-RestMethod -SkipCertificateCheck -Method Post -Uri "$base/graphql" -ContentType "application/json" -Body $body | ConvertTo-Json -Depth 8
```

Validate: products return, variable products expose `variations`, and prices are non-empty (they may contain `&nbsp;` and a currency symbol).

---

## 3. Login and JWT Lifetime

```powershell
$loginBody = @'
{"query":"mutation Login($u: String!, $p: String!) { login(input: { username: $u, password: $p }) { authToken refreshToken user { databaseId name email } customer { id sessionToken } } }","variables":{"u":"testcustomer","p":"<password>"}}
'@
$login = Invoke-RestMethod -SkipCertificateCheck -Method Post -Uri "$base/graphql" -ContentType "application/json" -Body $loginBody
$token = $login.data.login.authToken
$session = $login.data.login.customer.sessionToken

$payload = $token.Split('.')[1].Replace('-','+').Replace('_','/')
while ($payload.Length % 4) { $payload += '=' }
$claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
"lifetime_seconds=$($claims.exp - $claims.iat)"
```

Default lifetime is 300 seconds. A local mu-plugin can extend it with `graphql_jwt_auth_expire` returning `DAY_IN_SECONDS` (seconds, never a timestamp).

---

## 4. Profile

```powershell
$profileBody = '{"query":"query { viewer { id databaseId name email } customer { id databaseId displayName email billing { firstName lastName email phone } orders(first: 5) { nodes { databaseId orderNumber status total } } } }"}'
$headers = @{ Authorization = "Bearer $token"; 'X-JWT-Auth' = $token }
if ($session) { $headers['woocommerce-session'] = "Session $session" }
Invoke-RestMethod -SkipCertificateCheck -Method Post -Uri "$base/graphql" -ContentType "application/json" -Headers $headers -Body $profileBody | ConvertTo-Json -Depth 8
```

---

## 5. Cart Session

```powershell
$addBody = '{"query":"mutation Add($input: AddToCartInput!) { addToCart(input: $input) { cart { contents { itemCount } } cartItem { key quantity product { node { databaseId name } } } } }","variables":{"input":{"productId":10,"quantity":1}}}'
$add = Invoke-WebRequest -SkipCertificateCheck -Method Post -Uri "$base/graphql" -ContentType "application/json" -Body $addBody
$session = $add.Headers['Woocommerce-Session']

$cartBody = '{"query":"query { cart { total subtotal contents { itemCount nodes { key quantity total product { node { name } } } } } }"}'
Invoke-RestMethod -SkipCertificateCheck -Method Post -Uri "$base/graphql" -ContentType "application/json" -Headers @{ 'woocommerce-session' = "Session $session" } -Body $cartBody | ConvertTo-Json -Depth 8
```

The session header must be present and the second request must return the item.

---

## 6. Native Checkout Bridge

```powershell
$jar = Join-Path $env:TEMP "wc-cookies.txt"
Remove-Item $jar -ErrorAction SilentlyContinue

curl.exe -k -sS -L -c $jar -b $jar -o NUL -w "final=%{http_code} url=%{url_effective}`n" --resolve $resolve "$base/checkout/?fill_cart=10:1"

# Block checkout renders client-side; verify through the Store API with the same cookies
$cart = Invoke-RestMethod -SkipCertificateCheck -Uri "$base/wp-json/wc/store/v1/cart" -WebSession $null -Headers @{ Cookie = (Get-Content $jar | Where-Object { $_ -notmatch '^#' } | ForEach-Object { $p = $_ -split "`t"; "$($p[5])=$($p[6])" }) -join '; ' }
"items_count=$($cart.items_count) item=$($cart.items[0].name)"
```

For classic checkout, also verify `POST /checkout/?wc-ajax=update_order_review` is handled by WordPress.

---

## 7. Admin

```powershell
$jar = Join-Path $env:TEMP "admin-cookies.txt"
Remove-Item $jar -ErrorAction SilentlyContinue
curl.exe -k -sS -c $jar --resolve $resolve -o NUL "$base/wp-login.php"
curl.exe -k -sS -c $jar -b $jar --resolve $resolve --data-urlencode "log=admin" --data-urlencode "pwd=<password>" --data-urlencode "wp-submit=Log In" --data-urlencode "redirect_to=$base/wp-admin/" --data-urlencode "testcookie=1" -o NUL "$base/wp-login.php"
curl.exe -k -sS -L -b $jar --resolve $resolve -o $env:TEMP\admin.html -w "admin=%{http_code}`n" "$base/wp-admin/"
```

Expect 200 and a page containing `Dashboard`. A 500 usually means `pdo_mysql` is missing; check `docker logs wordpress`.

---

## 8. Build Gates

```powershell
$env:NODE_TLS_REJECT_UNAUTHORIZED = "0"
$env:NEXT_PUBLIC_WORDPRESS_API_URL = "$base/graphql"
$env:NEXT_PUBLIC_WORDPRESS_URL = "$base"
$env:NEXT_PUBLIC_BASE_URL = "$base"

pnpm lint
pnpm exec tsc --noEmit
pnpm test
pnpm build
```

Remove the TLS override when finished. Pages that read cookies are expected to be dynamic (`ƒ`), not statically generated.
