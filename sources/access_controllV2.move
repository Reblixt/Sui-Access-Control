module access_controll::access_controllV2 {
    use sui::vec_map::{Self, VecMap};

    public struct SRoles has key {
        id: UID,
        role: VecMap<ID, bool>,
    }

    public struct RoleCap<phantom T> has key {
        id: UID,
    }

    public struct OwnerCap has key {
        id: UID,
    }

    public fun new(ctx: &mut TxContext) {
        transfer::share_object(SRoles {
            id: object::new(ctx),
            role: vec_map::empty(),
        });
        transfer::transfer(OwnerCap { id: object::new(ctx) }, tx_context::sender(ctx));
    }

    public fun add_role<T: key>(
        _: &OwnerCap,
        roles: &mut SRoles,
        newAdmin: address,
        ctx: &mut TxContext,
    ) {
        let adminCap = RoleCap<T> { id: object::new(ctx) };
        let adminCapId: ID = object::id(&adminCap);

        vec_map::insert(&mut roles.role, adminCapId, true);

        transfer::transfer(adminCap, newAdmin)
    }

    public fun remove_role_cap(_: &OwnerCap, roles: &mut SRoles, adminCapId: ID) {
        vec_map::remove(&mut roles.role, &adminCapId);
    }

    public fun has_cap_access<T: key>(roles: &SRoles, roleCap: &RoleCap<T>): bool {
        let roleCapId: ID = object::id(roleCap);
        vec_map::contains(&roles.role, &roleCapId)
    }

    entry fun delete_cap<T: key>(roles: &mut SRoles, roleCap: RoleCap<T>) {
        let roleCapId: ID = object::id(&roleCap);
        vec_map::remove(&mut roles.role, &roleCapId);
        let RoleCap<T> { id } = roleCap;
        object::delete(id);
    }
}
