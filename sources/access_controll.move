module access_controll::access_controll {
    use sui::vec_map::{Self, VecMap};

    public struct SRoles has key {
        id: UID,
        admin: VecMap<ID, bool>,
        user: VecMap<ID, bool>,
    }

    public struct AdminCap has key, store {
        id: UID,
    }

    public struct UserCap has key, store {
        id: UID,
    }

    public struct OwnerCap has key {
        id: UID,
    }

    public fun new(ctx: &mut TxContext) {
        transfer::share_object(SRoles {
            id: object::new(ctx),
            admin: vec_map::empty(),
            user: vec_map::empty(),
        });
        transfer::transfer(OwnerCap { id: object::new(ctx) }, tx_context::sender(ctx));
    }

    public fun add_admin(_: &OwnerCap, roles: &mut SRoles, newAdmin: address, ctx: &mut TxContext) {
        let adminCap = AdminCap { id: object::new(ctx) };
        let adminCapId: ID = object::id(&adminCap);

        vec_map::insert(&mut roles.admin, adminCapId, true);

        transfer::transfer(adminCap, newAdmin)
    }

    public fun add_user(_: &OwnerCap, roles: &mut SRoles, newUser: address, ctx: &mut TxContext) {
        let userCap = UserCap { id: object::new(ctx) };
        let userCapId: ID = object::id(&userCap);

        vec_map::insert(&mut roles.user, userCapId, true);

        transfer::transfer(userCap, newUser)
    }

    public fun remove_admin(_: &OwnerCap, roles: &mut SRoles, adminCapId: ID) {
        vec_map::remove(&mut roles.admin, &adminCapId);
    }

    public fun remove_user(_: &OwnerCap, roles: &mut SRoles, userCapId: ID) {
        vec_map::remove(&mut roles.user, &userCapId);
    }

    public fun has_admin_access(roles: &SRoles, adminCap: &AdminCap): bool {
        let adminCapId: ID = object::id(adminCap);
        vec_map::contains(&roles.admin, &adminCapId)
    }

    public fun has_user_access(roles: &SRoles, userCap: &UserCap): bool {
        let userCapId: ID = object::id(userCap);
        vec_map::contains(&roles.user, &userCapId)
    }
}
