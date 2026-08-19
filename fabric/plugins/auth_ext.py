from __future__ import annotations

from schema.auth import AuthExtensionContext, SecurityContext  # pyright: ignore[reportMissingImports]

ROLE_ID_TAG_PREFIX = "roles:id:"
USER_ID_TAG_PREFIX = "users:id:"
GROUP_DELIMITER = ","
TAG_GROUP_MAP = {
    "roles:id:engineering-tenant-admin": "product_sandbox_tenant_admin",
    "users:id:kanakguptatmdcio": "retail_north_analyst",
    "users:id:shreyanegitmdcio": "retail_south_analyst",
    "users:id:anushkarakeshtmdcio": "retail_east_analyst",
    "users:id:rohitrajtmdcio": "retail_west_analyst",
}
POLICY_GROUP_PRIORITY = (
    "product_sandbox_tenant_admin",
    "retail_admin",
    "retail_north_analyst",
    "retail_south_analyst",
    "retail_east_analyst",
    "retail_west_analyst",
    "retail_central_analyst",
)


async def resolve_user_groups(ctx: AuthExtensionContext) -> SecurityContext:
    """
    Derive policy groups from Heimdall role and user tags.

    Args:
        ctx: Authorization extension context returned after Heimdall authorization.

    Returns:
        Security context containing the primary group and all role groups.
    """

    groups = []
    for tag in ctx.user_tags:
        if tag in TAG_GROUP_MAP:
            groups.append(TAG_GROUP_MAP[tag])
        elif tag.startswith(ROLE_ID_TAG_PREFIX):
            groups.append(tag.replace(ROLE_ID_TAG_PREFIX, "", 1).replace("-", "_"))
        elif tag.startswith(USER_ID_TAG_PREFIX):
            groups.append(tag.replace(USER_ID_TAG_PREFIX, "", 1).replace("-", "_"))

    DEFAULT_POLICY_GROUP = "roles:id:user"
    group = next(
        (policy_group for policy_group in POLICY_GROUP_PRIORITY if policy_group in groups),
        groups[0] if groups else DEFAULT_POLICY_GROUP,
    )
    return SecurityContext(group=group, groups=GROUP_DELIMITER.join(groups))