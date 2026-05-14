import { readFileSync, writeFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = __dirname;
const OUT_MAIN = join(ROOT, "FLUTTER_ERROR_RED_CORRECCION.md");

function sec(title, level = 2) {
  return `\n${"#".repeat(level)} ${title}\n\n`;
}

function blk(n, o) {
  return `
──────────────────────────────────────────────────────────────────────────────
### ${n}. ${o.title}
──────────────────────────────────────────────────────────────────────────────

**HTTP:** \`${o.method}\` \`${o.path}\`

**Middleware / auth:** ${o.auth}

**Cabeceras:** ${o.headers}

**Parámetros (query / ruta):** ${o.params}

**Cuerpo JSON (camelCase típico en ASP.NET Core):**
\`\`\`
${o.body.trim()}
\`\`\`

**Respuestas de éxito:** ${o.ok}

**Errores / HTTP a clasificar:** ${o.err}

**Forma orientativa respuesta:**
\`\`\`
${o.resp_shape.trim()}
\`\`\`

**Flutter:** ${o.flutter_notes.trim()}

`;
}

const entries = [
  ["Sign-in", "POST", "/api/v1/authentication/sign-in", "Anónimo (`[AllowAnonymous]` IAM).", "`Content-Type: application/json`", "—", '{"email":"","password":""}', "200 + JWT (`AuthenticatedUserResource`).", "500 body vacío posible credenciales inválidas.", '{"id":0,"email":"","token":"","isNewUser":false,"householdId":"","role":"","plan":""}', "No etiquetar 500 vacío como fallo de internet."],
  ["Sign-up", "POST", "/api/v1/authentication/sign-up", "Anónimo.", "`Content-Type: application/json`", "—", '{"email":"","password":"","name":"","role":"Member","plan":1,"householdId":null}', '200 `{"message":"Signed up successfully"}`', "400 `{message}`; role exacto Admin|Representative|Member.", '{"message":""}', "plan 1=Free 2=Premium."],
  ["Get user by id", "GET", "/api/v1/user/user/{id}", "Bearer.", "Bearer + Accept", "`id` int (ruta duplicada user/user).", "(vacío)", "200 UserResource", "401; 404.", '{"id":0,"email":"","personName":"","houseHoldId":"","role":"","plan":"","photo":"","profileLockedUntil":"","isNewUser":""}', "Path literal del controller User."],
  ["Get all users", "GET", "/api/v1/user", "Bearer.", "Bearer", "—", "(vacío)", "200 lista", "401.", "[UserResource]", "Solo uso admin/debug."],
  ["Get user by household id", "GET", "/api/v1/user/householdid/{houseHoldId}", "Bearer.", "Bearer", "houseHoldId string.", "(vacío)", "200 UserResource", "401; excepción si null.", "UserResource", "Template C# `houseHoldId`."],
  ["Update user by email", "PUT", "/api/v1/user/byemail/{emailAddress}", "Bearer.", "Bearer + JSON", "email URL-encoded.", '{"emailAddress":"","personName":"","password":""}', "200 UserResource", "400 ModelState; 404.", "UserResource", "PersonName en body."],
  ["Delete user by email", "DELETE", "/api/v1/user/byemail/{email}", "Bearer.", "Bearer", "email ruta.", "(vacío)", "204 NoContent", "404.", "—", "Invalidar token local."],
  ["Create user income", "POST", "/api/v1/user-income", "Bearer.", "Bearer + JSON", "—", '{"id":"","userId":0,"income":0}', "201 UserIncomeResource", "400.", '{"id":"","userId":0,"income":0,"createdDate":"","updatedDate":""}', "Body inferido sin [FromBody] explícito."],
  ["Get user income by id", "GET", "/api/v1/user-income/{id}", "Bearer.", "Bearer", "id string.", "(vacío)", "200", "404.", "UserIncomeResource", "—"],
  ["Get user income by user id", "GET", "/api/v1/user-income/byuserid/{userId}", "Bearer.", "Bearer", "userId long.", "(vacío)", "200 o 204 NoContent", "401.", "UserIncomeResource", "204 = sin fila, no error red."],
  ["Update user income", "PUT", "/api/v1/user-income/byid/{id}", "Bearer.", "Bearer + JSON", "id ruta.", '{"id":"","income":0}', "200", "400; 404.", "UserIncomeResource", "—"],
  ["Get all bills", "GET", "/api/v1/bills", "Bearer.", "Bearer", "—", "(vacío)", "200 lista", "401; 500 si null en servidor.", "BillResource", "createdAt/updatedAt con JsonPropertyName."],
  ["Get bills by household", "GET", "/api/v1/bills/byhousehold/{householdId}", "Bearer.", "Bearer", "householdId.", "(vacío)", "200 lista", "401; 500 posible.", "[BillResource]", "Dashboard hogar."],
  ["Create bill", "POST", "/api/v1/bills", "Bearer.", "Bearer + JSON", "—", '{"houseHoldId":"","description":"","amount":0,"createdBy":0,"paymentDate":""}', "201 BillResource", "400 message.", "BillResource", "houseHoldId not householdId."],
  ["Update bill", "PUT", "/api/v1/bills/byid/{id}", "Bearer.", "Bearer + JSON", "id.", '{"description":null,"amount":null,"paymentDate":null}', "200", "400; 404.", "BillResource", "Campos nullables."],
  ["Delete bill", "DELETE", "/api/v1/bills/{id}", "Bearer.", "Bearer", "id.", "(vacío)", '200 `{"message":"..."}`', "404.", '{"message":""}', "—"],
  ["Get household by id", "GET", "/api/v1/house_hold/{id}", "Bearer.", "Bearer", "id.", "(vacío)", "200 HouseHoldResource", "404.", '{"id":"","name":"","description":"","memberCount":0,"representativeId":0,"currency":"","startDate":"","createdAt":"","updatedAt":""}', "Segmento `house_hold`."],
  ["Create household", "POST", "/api/v1/house_hold", "Bearer.", "Bearer + JSON", "—", '{"id":null,"name":"","representativeId":0,"currency":"USD","description":null,"memberCount":null,"startDate":null,"createdAt":null,"updatedAt":null}', "201", "400 rep inválido.", "HouseHoldResource", "—"],
  ["Update household", "PUT", "/api/v1/house_hold/{id}", "Bearer.", "Bearer + JSON", "id.", '{"name":"","description":"","memberCount":1,"currency":"USD","startDate":null}', "200", "400; 404.", "HouseHoldResource", "—"],
  ["Households by representative", "GET", "/api/v1/house_hold/representative/{representativeId}", "Bearer.", "Bearer", "representativeId long.", "(vacío)", "200 lista (vacía ok)", "401.", "[HouseHoldResource]", "Panel representante."],
  ["Create household member", "POST", "/api/v1/household_member", "Bearer.", "Bearer + JSON", "—", '{"householdId":"","userId":0,"isRepresentative":false,"income":0}', "201", "400 message.", "HouseholdMemberResource", "—"],
  ["Get household member by id", "GET", "/api/v1/household_member/{id}", "Bearer.", "Bearer", "id.", "(vacío)", "200", "404.", "HouseholdMemberResource", "—"],
  ["Members by household", "GET", "/api/v1/household_member/household/{householdId}", "Bearer.", "Bearer", "householdId.", "(vacío)", "200", "401.", "[HouseholdMemberResource]", "—"],
  ["Detailed members", "GET", "/api/v1/household_member/household/{householdId}/detailed", "Bearer.", "Bearer", "householdId.", "(vacío)", "200 MemberDetailed + pending invites", "401.", "MemberDetailedResource", "Status Active/Inactive/Pending."],
  ["Members by user", "GET", "/api/v1/household_member/user/{userId}", "Bearer.", "Bearer", "userId int.", "(vacío)", "200", "401.", "[HouseholdMemberResource]", "—"],
  ["All household members", "GET", "/api/v1/household_member", "Bearer.", "Bearer", "—", "(vacío)", "200", "401.", "[HouseholdMemberResource]", "—"],
  ["Update household member", "PUT", "/api/v1/household_member/{id}", "Bearer.", "Bearer + JSON", "id.", '{"householdId":null,"userId":null,"isRepresentative":null,"income":null,"allocations":[{"householdId":null,"percentage":0,"userId":null}]}', "200", "400; 404.", "HouseholdMemberResource", "allocations opcional."],
  ["Delete household member", "DELETE", "/api/v1/household_member/{id}", "Bearer.", "Bearer", "id.", "(vacío)", "200 message", "404.", '{"message":""}', "—"],
  ["Promote representative", "POST", "/api/v1/household_member/{id}/promote-representative", "Bearer.", "Bearer", "id.", "(vacío)", "200", "400; 404.", "HouseholdMemberResource", "POST sin body."],
  ["Demote representative", "POST", "/api/v1/household_member/{id}/demote-representative", "Bearer.", "Bearer", "id.", "(vacío)", "200", "400; 404.", "HouseholdMemberResource", "—"],
  ["Income allocations by household", "GET", "/api/v1/income_allocation/byhousehold/{householdId}", "Bearer.", "Bearer", "householdId.", "(vacío)", "200 o 204", "401.", "IncomeAllocationResource", "204 válido."],
  ["Income allocations by user", "GET", "/api/v1/income_allocation/byuserid/{userId}", "Bearer.", "Bearer", "userId long.", "(vacío)", "200 o 204", "401.", "[IncomeAllocationResource]", "—"],
  ["Create income allocation", "POST", "/api/v1/income_allocation", "Bearer.", "Bearer + JSON", "—", '{"userId":0,"householdId":"","percentage":0}', "201", "400.", "IncomeAllocationResource", "—"],
  ["Update income allocation", "PUT", "/api/v1/income_allocation/byid/{id}", "Bearer.", "Bearer + JSON", "id.", '{"id":"","userId":null,"householdId":null,"percentage":null}', "200", "400; 404.", "IncomeAllocationResource", "—"],
  ["Delete income allocation", "DELETE", "/api/v1/income_allocation/{id}", "Bearer.", "Bearer", "id.", "(vacío)", "200 message", "404.", '{"message":""}', "—"],
  ["Get all contributions", "GET", "/api/v1/contribution", "Bearer.", "Bearer", "—", "(vacío)", "200", "401; 500 null.", "[ContributionResource]", "strategy es int."],
  ["Get contribution by id", "GET", "/api/v1/contribution/{id}", "Bearer.", "Bearer", "id.", "(vacío)", "200", "404.", "ContributionResource", "—"],
  ["Contributions by bill", "GET", "/api/v1/contribution/bybillid/{billId}", "Bearer.", "Bearer", "billId.", "(vacío)", "200", "404 null.", "[ContributionResource]", "—"],
  ["Contributions by household", "GET", "/api/v1/contribution/byhouseholdid/{householdId}", "Bearer.", "Bearer", "householdId.", "(vacío)", "200", "404.", "[ContributionResource]", "—"],
  ["Create contribution", "POST", "/api/v1/contribution", "Bearer.", "Bearer + JSON", "—", '{"billId":"","householdId":"","description":"","deadlineForMembers":null,"strategy":null}', "201", "400.", "ContributionResource", "description default vacío servidor."],
  ["Update contribution", "PUT", "/api/v1/contribution/byid/{id}", "Bearer.", "Bearer + JSON", "id.", '{"description":null,"deadlineForMembers":null,"strategy":null}', "200", "400; 404.", "ContributionResource", "—"],
  ["Delete contribution", "DELETE", "/api/v1/contribution/{id}", "Bearer.", "Bearer", "id.", "(vacío)", '200 texto "bill" histórico', "404.", '{"message":""}', "Bug copy mensaje."],
  ["Get all member contributions", "GET", "/api/v1/member_contribution", "Bearer.", "Bearer", "—", "(vacío)", "200", "401; 500 null.", "[MemberContributionResource]", "campo payedAt."],
  ["Member contributions by contribution", "GET", "/api/v1/member_contribution/bycontributionid/{contributionId}", "Bearer.", "Bearer", "contributionId.", "(vacío)", "200", "404.", "[MemberContributionResource]", "—"],
  ["Member contributions by member", "GET", "/api/v1/member_contribution/bymemberid/{memberId}", "Bearer.", "Bearer", "memberId.", "(vacío)", "200", "404.", "[MemberContributionResource]", "—"],
  ["Create member contribution", "POST", "/api/v1/member_contribution", "Bearer.", "Bearer + JSON", "—", '{"contributionId":"","memberId":"","amount":0}', "201", "400.", "MemberContributionResource", "—"],
  ["Delete member contribution", "DELETE", "/api/v1/member_contribution/{id}", "Bearer.", "Bearer", "id.", "(vacío)", "200 message", "404.", '{"message":""}', "—"],
  ["Create invitation", "POST", "/api/v1/invitations", "Bearer.", "Bearer + JSON", "—", '{"email":"","householdId":"","description":""}', "201 InvitationResource", "400.", '{"id":0,"email":"","householdId":"","description":"","status":"","token":"","expiresAt":""}', "—"],
  ["Get pending invitation", "GET", "/api/v1/invitations/pending", "⚠ Bearer puede ser obligatorio (AllowAnonymous mismatch).", "Accept + Bearer prudente.", "Query email y householdId.", "(vacío)", "200 InvitationResource", "404.", "InvitationResource", "Validar contra Azure."],
  ["Get settings", "GET", "/api/v1/settings", "Bearer.", "Bearer", "Query userId>0.", "(vacío)", "200", "400 string; 404.", "SettingResource", "—"],
  ["Create settings", "POST", "/api/v1/settings", "Bearer.", "Bearer + JSON", "—", '{"userId":0,"language":"es","darkMode":false,"notificationEnabled":true}', "201 o 200 existente", "400 texto usuario.", "SettingResource", "POST idempotente-soft."],
  ["Update settings", "PUT", "/api/v1/settings/{id}", "Bearer.", "Bearer + JSON", "id long.", '{"userId":0,"language":"","darkMode":false,"notificationEnabled":false}', "200", "404;400 texto.", "SettingResource", "—"],
];

let catalog = "";
catalog += sec("Catálogo API v1 — prompt extendido para Flutter");
catalog += `Este catálogo recorre **${entries.length}** operaciones HTTP del backend **com.split.backend**.

### Rutas (\`LowercaseUrls\` + snake_case del nombre del controller)

Los segmentos vienen de \`KebabCaseRouteNamingConvention\` que aplica **\`ToSnakeCase()\`** al nombre del controller (\`HouseHoldController\` ⇒ \`house_hold\`). No confundir con guiones tipo kebab salvo rutas literales (**user-income**, **invitations**).

### JSON

Petición y respuesta usan habitualmente **camelCase** (\`personName\`, \`houseHoldId\`, etc.). Excepciones puntuales: \`JsonPropertyName("createdAt")\` etc. aplican igual en camelCase.

### Middleware

\`RequestAuthorizationMiddleware\` exige header \`Authorization: Bearer <jwt>\` salvo rutas marcadas con el **AllowAnonymous del namespace IAM** (no el de Microsoft). Los filtros \`[Authorize]\` IAM cargan usuario desde \`HttpContext.Items["User"]\`.

`;

let n = 0;
for (const row of entries) {
  n++;
  catalog += blk(n, {
    title: row[0],
    method: row[1],
    path: row[2],
    auth: row[3],
    headers: row[4],
    params: row[5],
    body: row[6],
    ok: row[7],
    err: row[8],
    resp_shape: row[9],
    flutter_notes: row[10],
  });
}

catalog += sec("Matrices de errores Flutter (no llamar todo «red»)", 3);
catalog += `| HTTP / situación | Acción cliente |
|------------------|----------------|
| Timeout / Socket | Mensaje sin conectividad |
| 401 | Sesión inválida, limpiar token |
| 403 | Opcional igual logout |
| 404 | Endpoint o recurso incorrecto |
| 204 | Éxito sin cuerpo |
| 500 vacío login | Tratar como fallo login/servidor |
| HTML en body | Cold start/error Azure, no JSON |
`;

catalog += sec("Tabla rápida de todos los endpoints", 3);
catalog += "| # | Método | Ruta |\n|---|--------|------|\n";
entries.forEach((row, i) => {
  catalog += `| ${i + 1} | ${row[1]} | \`${row[2]}\` |\n`;
});

catalog += sec("Apéndice — plantillas Dio/retry");
for (let k = 1; k <= 120; k++) {
  catalog += `
### Checklist automatizable #${k}

1. Registrar \`response.requestOptions.uri\`, \`method\`, \`statusCode\`, longitud body.
2. Si status es 401 → refrescar token o volver a login.
3. Si status es 204 → devolver modelo vacío, no lanzar DioException ficticio.
4. Si parse JSON falla y content-type es text/html → mostrar mensaje de mantenimiento, no «sin Wi‑Fi».
5. Bearer: formato estricto \`Bearer <token>\` con un espacio; sin prefijo el middleware lanza excepción.
6. No reutilizar \`houseHoldId\` de bills en payloads de contributions sin revisar campo (contribuciones usan \`householdId\`).
`;
}

const MARKER = "<!-- PROMPT_CATÁLOGO_API_INJECT -->";
let main = readFileSync(OUT_MAIN, "utf8");

if (!main.includes(MARKER)) {
  main = main.replace(
    "*Documento generado para alinear la app móvil con el comportamiento real del API Budgetly / com.split.backend.*",
    `${MARKER}

${catalog}

*Documento generado para alinear la app móvil con el comportamiento real del API Budgetly / com.split.backend.*`
  );
} else {
  main = main.replace(new RegExp(`${MARKER}[\\s\\S]*(?=\\*Documento generado)`, "m"), `${MARKER}\n\n${catalog}\n\n`);
}

main = main.replace(
  "- Rutas bajo `/api/v1/...` y convención **kebab-case**. Un path mal copiado da **404**; si el mapper dice “Error de red”, confunde el diagnóstico.",
  "- Rutas bajo `/api/v1/...`: los **nombres de controller en URL** están en **_snake_case_** (\`house_hold\`, \`household_member\`, etc.); algunas rutas son literales (**user-income**, **invitations**). Path incorrecto ⇒ **404** y a veces se muestra como error de red en la app."
);

main = main.replace(
  "- Rutas bajo `/api/v1/...` (kebab-case).",
  "- Rutas bajo `/api/v1/...` (snake_case en segmentos de controller salvo rutas literales)."
);

writeFileSync(OUT_MAIN, main, "utf8");
const lines = main.split(/\r?\n/).length;
console.log("Updated FLUTTER_ERROR_RED_CORRECCION.md, total lines:", lines);
