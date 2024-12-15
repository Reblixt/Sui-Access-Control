module access_controll::access_controllV2 {
    use sui::vec_map::{Self, VecMap};

    public struct SRoles has key {
        id: UID,
        // mapping from role capability id to bool
        role: VecMap<ID, bool>,
    }

    // RoleCap is a phantom type that is used to create a new role capability
    // and make sure that the role has key and are soulbound and can only be
    // Deleted by the holder.
    public struct RoleCap<phantom T> has key {
        id: UID,
    }

    public struct OwnerCap has key {
        id: UID,
    }

    /// @notice Creates a new access control shared object and transfers ownership
    /// @notice The sender of the transaction will be the owner of the access control
    /// @param ctx The transaction context
    /// @return None - Creates a shared SRoles object and transfers OwnerCap to sender
    public fun new(ctx: &mut TxContext) {
        transfer::share_object(SRoles {
            id: object::new(ctx),
            role: vec_map::empty(),
        });
        transfer::transfer(OwnerCap { id: object::new(ctx) }, tx_context::sender(ctx));
    }

    /// @dev Only the owner can add a new role
    /// @dev Need to create a new role that has key ability
    /// @notice Adds a new role to the access control system
    /// @param _ The owner capability reference
    /// @param roles The shared object that contains the roles
    /// @param recipient The address that will receive the new role capability
    /// @param ctx The transaction context
    public fun add_role<T: key>(
        _: &OwnerCap,
        roles: &mut SRoles,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let adminCap = RoleCap<T> { id: object::new(ctx) };
        let adminCapId: ID = object::id(&adminCap);

        vec_map::insert(&mut roles.role, adminCapId, true);

        transfer::transfer(adminCap, recipient);
    }

    /// @dev Only the owner can remove a role
    /// @notice Removes a role from the access control system
    /// @param _ The owner capability reference
    /// @param roles The shared object that contains the roles
    /// @param adminCapId The ID of the role capability to be removed
    public fun remove_role_cap(_: &OwnerCap, roles: &mut SRoles, adminCapId: ID) {
        vec_map::remove(&mut roles.role, &adminCapId);
    }

    /// @notice Checks if a role has access to a specific capability
    /// @dev This is the core function that checks if a role has access and should be combined
    /// with assert! to check if a role has access to a specific capability
    /// @param roles The shared object that contains the roles
    /// @param roleCap The role capability to check
    /// @return bool Returns true if the role has access, false otherwise
    public fun has_cap_access<T: key>(roles: &SRoles, roleCap: &RoleCap<T>): bool {
        let roleCapId: ID = object::id(roleCap);
        vec_map::contains(&roles.role, &roleCapId)
    }

    /// @notice Deletes a role capability
    /// @dev This function is called by the holder of the role capability to delete it.
    /// It will remove the role capability from the roles shared object and delete the role capability
    /// @param roles The shared object that contains the roles
    /// @param roleCap The role capability to be deleted
    entry fun delete_cap<T: key>(roles: &mut SRoles, roleCap: RoleCap<T>) {
        let roleCapId: ID = object::id(&roleCap);
        vec_map::remove(&mut roles.role, &roleCapId);
        let RoleCap<T> { id } = roleCap;
        object::delete(id);
    }
}
