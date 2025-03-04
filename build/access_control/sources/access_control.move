// SPDX-License-Identifier: MIT

module access_control::access_control {
    use sui::{event::emit, vec_map::{Self, VecMap}};

    public struct SRoles<phantom T> has key {
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
    public struct OwnerCap<phantom T> has key, store {
        id: UID,
    }

    // ======================= Error ==========================
    const ENotOneTimeWitness: u64 = 1;

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
    #[allow(lint(self_transfer))]
    public fun default<T: drop>(otw: &T, ctx: &mut TxContext) {
        transfer::public_transfer(new<T>(otw, ctx), ctx.sender());
    }

    /// @notice Creates a new access control shared object and transfers ownership
    /// @param ctx The transaction context
    /// @return OwnerCap The owner capability reference
    public fun new<T: drop>(otw: &T, ctx: &mut TxContext): OwnerCap<T> {
        assert!(sui::types::is_one_time_witness(otw), ENotOneTimeWitness);
        let new_sroles = object::new(ctx);
        let s_roles_id = new_sroles.to_inner();
        transfer::share_object(SRoles<T> {
            id: new_sroles,
            role: vec_map::empty(),
        });
        let new_owner_cap = object::new(ctx);
        let owner_cap_id = new_owner_cap.to_inner();

        emit(NewCreatedSharedRolesEvent {
            owner_cap_id,
            s_roles_id,
        });
        OwnerCap<T> { id: new_owner_cap }
    }

    /// @dev Only the owner can add a new role
    /// @dev Need to create a new role that has key ability
    /// @notice Adds a new role to the access control system
    /// @param _ The owner capability reference
    /// @param roles The shared object that contains the roles
    /// @param recipient The address that will receive the new role capability
    /// @param ctx The transaction context
    public fun add_role<T, R: key>(
        _: &OwnerCap<T>,
        roles: &mut SRoles<T>,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let adminCap = RoleCap<R> { id: object::new(ctx) };
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
    public fun revoke_role_access<T>(
        _: &OwnerCap<T>,
        roles: &mut SRoles<T>,
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
    public fun has_cap_access<T, R: key>(roles: &SRoles<T>, roleCap: &RoleCap<R>): bool {
        let roleCapId: ID = object::id(roleCap);
        vec_map::contains(&roles.role, &roleCapId)
    }

    /// @notice Deletes a role capability
    /// @dev This function is called by the holder of the role capability to delete it.
    /// It will remove the role capability from the roles shared object and delete the role capability
    /// @param roles The shared object that contains the roles
    /// @param roleCap The role capability to be deleted
    public fun delete_cap<T, R: key>(roles: &mut SRoles<T>, roleCap: RoleCap<R>, ctx: &TxContext) {
        let roleCapId: ID = object::id(&roleCap);
        vec_map::remove(&mut roles.role, &roleCapId);
        let RoleCap<R> { id } = roleCap;
        object::delete(id);

        emit(RoleDeletedEvent {
            owner: tx_context::sender(ctx),
            roleId: roleCapId,
        });
    }

    #[test_only]
    public struct ACCESS_CONTROL has drop {}
    #[test_only]
    public(package) fun init_test(ctx: &mut TxContext) {
        let otw = ACCESS_CONTROL {};
        default(&otw, ctx);
    }
}
