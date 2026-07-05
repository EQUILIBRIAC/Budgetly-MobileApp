"""One-shot migration: replace hardcoded strings in representative_screens.dart."""
from pathlib import Path
import re

FILE = Path(__file__).resolve().parents[1] / "lib/features/representative/presentation/screens/representative_screens.dart"

# (spanish, english) pairs — order: longer strings first
PAIRS = [
    ("Copiado al portapapeles", "Copied to clipboard"),
    ("Estado y marcar aportes como pagados", "Status and mark contributions as paid"),
    ("Reparto IncomeBased por miembro", "IncomeBased split per member"),
    ("Espera a que carguen los datos o crea un hogar en «Hogares».", "Wait for data to load or create a household in «Households»."),
    ("Tu cuenta no tiene un ID numérico de usuario para crear facturas.", "Your account has no numeric user ID to create bills."),
    ("Completa descripción y un monto válido.", "Enter a description and a valid amount."),
    ("Factura registrada.", "Bill registered."),
    ("Guardar factura", "Save bill"),
    ("La otra persona debe tener cuenta en Budgetly y pasarte su ID de usuario (en su app: Ajustes).",
     "The other person needs a Budgetly account and must share their user ID (in their app: Settings)."),
    ("La otra persona debe tener cuenta en Budgetly y pasarte ", None),  # handled below
    ("Invitar por correo (alternativa)", "Invite by email (alternative)"),
    ("ID numérico del usuario", "Numeric user ID"),
    ("Ingreso estimado (opcional)", "Estimated income (optional)"),
    ("Es miembro del hogar", "Is a household member"),
    ("Tiene rol de representante", "Has representative role"),
    ("Ingresa un ID de usuario o un correo para invitar.", "Enter a user ID or email to invite."),
    ("Miembro vinculado al hogar.", "Member linked to household."),
    ("Añadir miembro", "Add member"),
    ("Primero registra una factura en «Facturas».", "Register a bill in «Bills» first."),
    ("Elige la factura a repartir y avisa hasta cuándo deben pagar.", "Choose the bill to split and set the payment deadline."),
    ("Nota para el equipo (opcional)", "Team note (optional)"),
    ("Contribución registrada.", "Contribution registered."),
    ("Crear contribución", "Create contribution"),
    ("Fecha de pago objetivo", "Target payment date"),
    ("Datos incompletos.", "Incomplete data."),
    ("Factura actualizada.", "Bill updated."),
    ("Editar factura", "Edit bill"),
    ("Día de pago", "Payment day"),
    ("Número de miembros", "Number of members"),
    ("Según API PUT /house_hold/{id}", "Per API PUT /house_hold/{id}"),
    ("Nombre y número de miembros válidos.", "Enter a valid name and member count."),
    ("Hogar actualizado.", "Household updated."),
    ("¿Eliminar esta factura del hogar? (DELETE /api/v1/bills/{id})", "Delete this bill from the household? (DELETE /api/v1/bills/{id})"),
    ("Eliminar factura", "Delete bill"),
    ("Factura eliminada.", "Bill deleted."),
    ("Quitar la vinculación de esta persona con el hogar (DELETE /api/v1/household_member/{id}).",
     "Remove this person's link to the household (DELETE /api/v1/household_member/{id})."),
    ("Quitar la vinculación de esta persona con el hogar ", None),
    ("Miembro quitado del hogar.", "Member removed from household."),
    ("Eliminar aporte", "Delete contribution"),
    ("¿Eliminar esta contribución?", "Delete this contribution?"),
    ("Contribución eliminada.", "Contribution deleted."),
    ("Aún no tienes un hogar activo.", "You don't have an active household yet."),
    ("Ve a «Hogares» y crea el primero con «Nuevo hogar» para empezar.", "Go to «Households» and create your first with «New household» to get started."),
    ("Ir a Hogares", "Go to Households"),
    ("Administra tu hogar con claridad", "Manage your household with clarity"),
    ("Gastos totales", "Total expenses"),
    ("Gestiona tu hogar", "Manage your household"),
    ("Salario de miembros", "Member salaries"),
    ("Invita y administra", "Invite and manage"),
    ("Facturas del hogar", "Household bills"),
    ("Reparto de pagos", "Payment split"),
    ("Cuenta y preferencias", "Account and preferences"),
    ("Crear y elegir activo", "Create and select active"),
    ("Nueva factura", "New bill"),
    ("Invitar miembro", "Invite member"),
    ("Nueva contribución", "New contribution"),
    ("Facturas vencidas", "Overdue bills"),
    ("Seguimiento pendiente", "Pending follow-up"),
    ("Nuevo hogar", "New household"),
    ("Aún no tienes hogares registrados.", "You have no households yet."),
    ("Crea el primero con «Nuevo hogar». Luego podrás agregar facturas y miembros.", "Create the first with «New household». Then add bills and members."),
    ("Sin descripción", "No description"),
    ("Copiar ID del hogar", "Copy household ID"),
    ("Hogar activo actualizado.", "Active household updated."),
    ("Usar este hogar", "Use this household"),
    ("Agregar miembro", "Add member"),
    ("Aquí aparecerán quienes comparten tus gastos.", "People who share your expenses will appear here."),
    ("Cada persona necesita cuenta en Budgetly. Pídeles su ID numérico (lo ven como miembro en Ajustes) y vínculos aquí.",
     "Each person needs a Budgetly account. Ask for their numeric ID (visible in Settings as a member) and link them here."),
    ("Invitar primer miembro", "Invite first member"),
    ("Registrar ingresos mensuales", "Register monthly incomes"),
    ("Ingreso mensual: sin registrar", "Monthly income: not set"),
    ("Copiar correo", "Copy email"),
    ("Ascender a representante", "Promote to representative"),
    ("Degradar a miembro", "Demote to member"),
    ("Quitar del hogar", "Remove from household"),
    ("Registra servicios, alquiler o cualquier gasto recurrente.", "Record utilities, rent or any recurring expense."),
    ("Cuando existan facturas podrás crear contribuciones para repartirlas.", "Once bills exist you can create contributions to split them."),
    ("Registrar factura", "Register bill"),
    ("Sin fecha", "No date"),
    ("Ver pagos", "View payments"),
    ("Ver desglose", "View breakdown"),
    ("Las contribuciones reparten el pago de una factura.", "Contributions split payment for a bill."),
    ("Registra facturas en «Gastos» y vuelve a crear un aporte.", "Register bills in «Expenses» and create a contribution."),
    ("Gastos base", "Base expenses"),
    ("Registradas", "Registered"),
    ("Copiar ID", "Copy ID"),
    ("Desglose por miembro", "Breakdown by member"),
    ("Crear hogar", "Create household"),
    ("Nombre del hogar", "Household name"),
    ("Descripción (opcional)", "Description (optional)"),
    ("El nombre es obligatorio.", "Name is required."),
    ("Hogar creado. Actualizando datos…", "Household created. Refreshing data…"),
    ("Equipo activo", "Active team"),
    ("Invitar miembro", "Invite member"),
    ("Nombre (opcional)", "Name (optional)"),
    ("Fecha límite", "Deadline"),
    ("Editar hogar", "Edit household"),
    ("Quitar miembro", "Remove member"),
    ("Invitación enviada a ", "Invitation sent to "),  # partial - use t with interpolation separately
    ("Bienvenido,", "Welcome,"),
    ("Tu hogar", "Your household"),
    ("ID del hogar:", "Household ID:"),
    ("Hogar:", "Household:"),
    ("Descripción", "Description"),
    ("Ej. Luz marzo", "E.g. March electricity"),
    ("Ej. Juan", "E.g. John"),
    ("Ej. 12", "E.g. 12"),
    ("Ej. Departamento centro", "E.g. Downtown apartment"),
    ("persona@ejemplo.com", "person@example.com"),
    ("Moneda:", "Currency:"),
    ("Soles (PEN)", "Soles (PEN)"),
    ("Dólares (USD)", "US Dollars (USD)"),
    ("Nombre", "Name"),
    ("Factura", "Bill"),
    ("Cerrar", "Close"),
    ("Quitar", "Remove"),
    ("No", "No"),
    ("Editar", "Edit"),
    ("Eliminar", "Delete"),
    ("Crear", "Create"),
    ("Activo", "Active"),
    ("Cancelar", "Cancel"),
    ("Guardar", "Save"),
    ("Reintentar", "Retry"),
]

def t_expr(es: str, en: str) -> str:
    es_esc = es.replace("'", "\\'")
    en_esc = en.replace("'", "\\'")
    return f"l.t('{es_esc}', '{en_esc}')"

def main():
    text = FILE.read_text(encoding="utf-8")
    if "app/l10n/app_localizations.dart" not in text:
        text = text.replace(
            "import 'package:budgetly_app/features/auth/presentation/providers/auth_providers.dart';",
            "import 'package:budgetly_app/app/l10n/app_localizations.dart';\n"
            "import 'package:budgetly_app/features/auth/presentation/providers/auth_providers.dart';",
        )

    # Remove const from Text widgets that will use l10n (simple heuristic)
    for es, en in PAIRS:
        if en is None:
            continue
        expr = t_expr(es, en)
        # _repSnack(context, '...')
        text = text.replace(f"_repSnack(context, '{es}')", f"_repSnack(context, {expr})")
        text = text.replace(f"_repSnack(hostContext, '{es}')", f"_repSnack(hostContext, {expr})")
        text = text.replace(f"_repSnack(ctx, '{es}')", f"_repSnack(ctx, {expr})")
        # message: '...' in _RepEmpty
        text = text.replace(f"message: '{es}'", f"message: {expr}")
        text = text.replace(f"hint: '{es}'", f"hint: {expr}")
        text = text.replace(f"hint:\n                  '{es}'", f"hint: {expr}")
        text = text.replace(f"message:\n                        '{es}'", f"message: {expr}")
        text = text.replace(f"hint:\n                        '{es}'", f"hint: {expr}")

    # Inject l = context.l10n in build methods of ConsumerWidget/StatelessWidget classes
    build_pattern = re.compile(
        r"(Widget build\(BuildContext context(?:, WidgetRef ref)?\) \{\n)"
        r"(?!    final l = context\.l10n;)"
    )
    text = build_pattern.sub(r"\1    final l = context.l10n;\n", text)

    # StatefulBuilder inner builder - use AppLocalizations.of(context)
    sb_pattern = re.compile(
        r"(builder: \(context, setState\) \{\n)(?!          final l = context\.l10n;)"
    )
    text = sb_pattern.sub(
        r"\1          final l = context.l10n;\n", text
    )

    # Dialog builder
    dialog_pattern = re.compile(
        r"(builder: \(context\) \{\n)(?!      final l = context\.l10n;)"
    )
    text = dialog_pattern.sub(r"\1      final l = context.l10n;\n", text)

    # Modal bottom sheet builder (ctx)
    sheet_pattern = re.compile(
        r"(builder: \(ctx\) \{\n)(?!      final l = AppLocalizations\.of\(ctx\);)"
    )
    text = sheet_pattern.sub(
        r"\1      final l = AppLocalizations.of(ctx);\n", text
    )

    for es, en in PAIRS:
        if en is None:
            continue
        expr = t_expr(es, en)
        # const Text('...')
        text = text.replace(f"const Text('{es}')", f"Text({expr})")
        text = text.replace(f'const Text("{es}")', f"Text({expr})")
        # label: const Text
        text = text.replace(f"label: const Text('{es}')", f"label: Text({expr})")
        # title/subtitle in ListTile
        text = text.replace(f"title: const Text('{es}')", f"title: Text({expr})")
        text = text.replace(f"subtitle: const Text('{es}')", f"subtitle: Text({expr})")
        # labelText / hintText in InputDecoration
        text = text.replace(f"labelText: '{es}'", f"labelText: {expr}")
        text = text.replace(f"hintText: '{es}'", f"hintText: {expr}")
        text = text.replace(f"helperText: '{es}'", f"helperText: {expr}")
        # child: Text in PopupMenuItem - remove const from parent
        text = text.replace(
            f"child: Text('{es}')",
            f"child: Text({expr})",
        )

    # Functions at top level that use context - add l at start
    for fn in ["_copyToClipboard", "_requireLoadedHousehold", "_openCreateBillSheet", "_openAddMemberSheet", "_openContributionSheet"]:
        pass  # handled via context.l10n inline in _repSnack replacements

    # _copyToClipboard special
    text = text.replace(
        "_repSnack(context, l.t('Copiado al portapapeles', 'Copied to clipboard'))",
        "_repSnack(context, AppLocalizations.of(context).t('Copiado al portapapeles', 'Copied to clipboard'))",
    )

    # _requireLoadedHousehold - no l in scope, use AppLocalizations.of(context)
    text = re.sub(
        r"_repSnack\(\n      context,\n      l\.t\(",
        "_repSnack(\n      context,\n      AppLocalizations.of(context).t(",
        text,
    )

    # Fix multiline strings for invite hint
    old_hint = """                  Text(
                    'La otra persona debe tener cuenta en Budgetly y pasarte '
                    'su ID de usuario (en su app: Ajustes).',"""
    new_hint = """                  Text(
                    l.t(
                      'La otra persona debe tener cuenta en Budgetly y pasarte '
                      'su ID de usuario (en su app: Ajustes).',
                      'The other person needs a Budgetly account and must share '
                      'their user ID (in their app: Settings).',
                    ),"""
    text = text.replace(old_hint, new_hint)

    old_del_member = """      content: const Text(
        'Quitar la vinculación de esta persona con el hogar '
        '(DELETE /api/v1/household_member/{id}).',
      ),"""
    new_del_member = """      content: Text(
        l.t(
          'Quitar la vinculación de esta persona con el hogar '
          '(DELETE /api/v1/household_member/{id}).',
          'Remove this person\\'s link to the household '
          '(DELETE /api/v1/household_member/{id}).',
        ),
      ),"""
    text = text.replace(old_del_member, new_del_member)

    # Invitation sent with email interpolation
    text = text.replace(
        """                            _repSnack(
                              hostContext,
                              'Invitación enviada a $email.',
                            )""",
        """                            _repSnack(
                              hostContext,
                              l.t(
                                'Invitación enviada a $email.',
                                'Invitation sent to $email.',
                              ),
                            )""",
    )

    # Promote/demote snackbars - need l in scope in onSelected
    text = text.replace(
        "'${member.displayName} ahora es representante.'",
        "l.t('${member.displayName} ahora es representante.', '${member.displayName} is now a representative.')",
    )
    text = text.replace(
        "'${member.displayName} ahora es miembro.'",
        "l.t('${member.displayName} ahora es miembro.', '${member.displayName} is now a member.')",
    )

    # Household admin count text - complex plural
    text = re.sub(
        r"'Administras \$\{homes\.length\} hogar\$\{homes\.length == 1 \? '' : 'es'\}\. '\s*\n\s*'El marcado como activo es el que usan las demás pestañas\.'",
        "l.t(\n                'Administras ${homes.length} hogar${homes.length == 1 ? '' : 'es'}. '\n                'El marcado como activo es el que usan las demás pestañas.',\n                'You manage ${homes.length} household${homes.length == 1 ? '' : 's'}. '\n                'The one marked active is used by the other tabs.',\n              )",
        text,
    )

    # member count
    text = re.sub(
        r"'\$\{h\.memberCount\} miembro\$\{h\.memberCount == 1 \? '' : 's'\}'",
        "l.t('${h.memberCount} miembro${h.memberCount == 1 ? '' : 's'}', '${h.memberCount} member${h.memberCount == 1 ? '' : 's'}')",
        text,
    )

    # paid count on bills
    text = re.sub(
        r"'\$\{progress\.paidMembersCount\}/\$\{progress\.totalMembersCount\} pagados'",
        "l.t('${progress.paidMembersCount}/${progress.totalMembersCount} pagados', '${progress.paidMembersCount}/${progress.totalMembersCount} paid')",
        text,
    )

    # Vence: dueDate
    text = re.sub(
        r"'Vence: \$dueDate'",
        "l.t('Vence: $dueDate', 'Due: $dueDate')",
        text,
    )

    # Moneda
    text = re.sub(
        r"'Moneda \$\{h\.currency\}'",
        "l.t('Moneda ${h.currency}', 'Currency ${h.currency}')",
        text,
    )

    # Income monthly line
    text = re.sub(
        r"'Ingreso mensual: \$sym\$\{member\.income\.toStringAsFixed\(2\)\}'",
        "l.t('Ingreso mensual: $sym${member.income.toStringAsFixed(2)}', 'Monthly income: $sym${member.income.toStringAsFixed(2)}')",
        text,
    )

    # Remove duplicate l injection in nested builders if double
    text = text.replace(
        "          final l = context.l10n;\n          final l = context.l10n;\n",
        "          final l = context.l10n;\n",
    )

    FILE.write_text(text, encoding="utf-8")
    print("Done migrating", FILE)

if __name__ == "__main__":
    main()
