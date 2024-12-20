// SPDX-License-Identifier: MIT

module access_control::access_control {
    use sui::{event::emit, vec_map::{Self, VecMap}};

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

    /// This is the OwnerCap if for modifie SRoles shared object
    public struct OwnerCap<phantom T> has key {
        id: UID,
    }

    // ======================== Events ========================

    public struct NewCreatedSharedRolesEvent has copy, drop {
        owner_cap_id: ID,
        s_roles_id: ID,
    }

    public struct RoleAddedEvent has copy, drop {
        owner: address,
        roleId: ID,
    }

    public struct RoleRevokedEvent has copy, drop {
        owner: address,
        roleId: ID,
    }

    public struct RoleDeletedEvent has copy, drop {
        owner: address,
        roleId: ID,
    }

    /// @notice Creates a new access control shared object and transfers ownership
    /// @notice The sender of the transaction will be the owner of the access control
    /// @param ctx The transaction context
    /// @return None - Creates a shared SRoles object and transfers OwnerCap to sender
    public fun new<T>(ctx: &mut TxContext) {
        let new_sroles = object::new(ctx);
        let s_roles_id = new_sroles.to_inner();
        transfer::share_object(SRoles {
            id: new_sroles,
            role: vec_map::empty(),
        });
        let new_owner_cap = object::new(ctx);
        let owner_cap_id = new_owner_cap.to_inner();
        transfer::transfer(OwnerCap<T> { id: new_owner_cap }, tx_context::sender(ctx));

        emit(NewCreatedSharedRolesEvent {
            owner_cap_id,
            s_roles_id,
        });
    }

    /// @dev Only the owner can add a new role
    /// @dev Need to create a new role that has key ability
    /// @notice Adds a new role to the access control system
    /// @param _ The owner capability reference
    /// @param roles The shared object that contains the roles
    /// @param recipient The address that will receive the new role capability
    /// @param ctx The transaction context
    public fun add_role<T: key, O>(
        _: &OwnerCap<O>,
        roles: &mut SRoles,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let adminCap = RoleCap<T> { id: object::new(ctx) };
        let adminCapId: ID = object::id(&adminCap);

        vec_map::insert(&mut roles.role, adminCapId, true);

        transfer::transfer(adminCap, recipient);

        emit(RoleAddedEvent {
            owner: tx_context::sender(ctx),
            roleId: adminCapId,
        });
    }

    /// @dev Only the owner can remove a role
    /// @notice Revoke a role from the access control system
    /// @param _ The owner capability reference
    /// @param roles The shared object that contains the roles
    /// @param adminCapId The ID of the role capability to be removed
    public fun revoke_role_access<T: key>(
        _: &OwnerCap<T>,
        roles: &mut SRoles,
        adminCapId: ID,
        ctx: &TxContext,
    ) {
        vec_map::remove(&mut roles.role, &adminCapId);

        emit(RoleRevokedEvent {
            owner: tx_context::sender(ctx),
            roleId: adminCapId,
        });
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
    entry fun delete_cap<T: key>(roles: &mut SRoles, roleCap: RoleCap<T>, ctx: &TxContext) {
        let roleCapId: ID = object::id(&roleCap);
        vec_map::remove(&mut roles.role, &roleCapId);
        let RoleCap<T> { id } = roleCap;
        object::delete(id);

        emit(RoleDeletedEvent {
            owner: tx_context::sender(ctx),
            roleId: roleCapId,
        });
    }
}
