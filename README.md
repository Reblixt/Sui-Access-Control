# Update 2024-12-20
Patched a security vulnarability in the OwnerCap.

Now you need to add a Type specific to your Dapp/Project when you call the `new` function. 
So the ownercap is tied to the specific project. 

```rust
    public struct PROJECT {}

    fun init(otw: PROJECT, ctx: &mut TxContext) {
    // Initialize the access control mechanism
    access_control::new<PROJECT>(&otw,ctx);
    // OwnerCap is minted and transferred to the transaction sender (ctx)
    }
```

# Sui-Access-Control
This repository contains a Sui Move module that implements a simple, flexible, and free-to-use role-based access control mechanism on the Sui network. The `Sui-access-control` module allows for granular permissions management by creating, assigning, and revoking "capabilities" represented by roles, all governed by an on-chain "owner" entity.

## Motivation 
I am on my journey to learn Sui Move. I have seen this question asked many times and wondered myself how this kind of access controll would look like. So i decided to build it and then share it. 

## Overview

This module provides a straightforward way to:

  -  Establish a shared roles object (SRoles) for storing role capabilities.
  -  Create and assign new roles to addresses.
  -  Check whether a given role has access to certain capabilities.
  -  Revoke roles and cleanly remove their associated capabilities.

By leveraging this module, developers can integrate robust authorization logic directly into their Sui Move contracts, ensuring that only the right parties have permission to execute specific actions.
## Key Concepts
`SRoles<T>`

A shared on-chain object that maintains the state of assigned roles. It maps role capability IDs to a boolean value indicating whether the role currently has access.

`OwnerCap<T>`

A unique capability that grants the holder the authority to manage roles. Only the owner can create and revoke roles, ensuring a single source of truth for permission modifications.

`RoleCap<R>`

A "role capability" object parameterized by a phantom type T. Each RoleCap represents a distinct role with a unique ID. Holders of this capability demonstrate that they have a particular role and associated permissions.
## Core Functions
```rust 

    default new<T>(otw: T, ctx: &mut TxContext)
    // Initializes the access control mechanism:
    // Creates a new shared SRoles object on-chain.
    // Mints and trasferred an OwnerCap to the transaction sender.

    new(otw<T>, ctx: &mut TxContext): OwnerCap<T>
    // Initializes the access control mechanism:
    // Creates a new shared SRoles object on-chain.
    // Mints and returns an OwnerCap.

    add_role<T, R: key>(owner_cap: &OwnerCap<T>, roles: &mut SRoles<T>, recipient: address, ctx: &mut TxContext)
    // Assigns a new role capability to a specified recipient. Only the holder of the 
    //OwnerCap can add new roles.

    revoke_role_access<T>(owner_cap: &OwnerCap<T>, roles: &mut SRoles<T>, role_id: ID)
    // Revoke a role from the access. Only the holder of the OwnerCap can remove roles. 

    has_cap_access<T, R: key>(roles: &SRoles<T>, role_cap: &RoleCap<R>): bool
    // Checks if a given role capability is currently active and has access rights. 
    // Useful for gating contract functions that should only be executed by certain roles.

    delete_cap<T, R: key>(roles: &mut SRoles, role_cap: RoleCap<T>)
    // Allows the holder of a role capability to voluntarily delete their 
    // RoleCap. This removes the corresponding entry from SRoles and destroys 
    // the role capability object.

```
## Why Use This Module?

- Simplicity: The module provides a minimal and clean interface for developers to integrate role-based access control into their projects without reinventing the wheel.
- Flexibility: By parameterizing `RoleCap` with a phantom type `T`, developers can create multiple, distinct roles that enforce access policies within their contracts.
- On-Chain Guarantees: Role assignment, revocation, and verification occur on-chain, providing transparency and trustlessness.
- Free to Use: This module is released for public use. You are free to copy, modify, and integrate it into your own projects and adapt it to your needs.

## Example of Usage

```rust
module something::project {
use access_control::access_control::{Self, OwnerCap, RoleCap, SRoles};

const ENotAuthorized: u64 = 1;

    // One time witness
    public struct PROJECT has drop {}
    // Need to have a key ability!
    public struct MyOwnRole has key {
    id: UID, 
    }

    fun init(otw: PROJECT, ctx: &mut TxContext) {
    // Initialize the access control mechanism
    access_control::default<PROJECT>(&otw,ctx);
    // OwnerCap is minted and transferred to the transaction sender (ctx)
    }

    public fun create_role(owner_cap: &OwnerCap<PROJECT>, roles: &mut SRoles<PROJECT>, recipient: address, ctx: &mut TxContext) {
    // Create a new role capability and assign it to the recipient
    access_control::add_role<PROJECT, MyOwnRole>(owner_cap, roles, recipient, ctx);
    }

    public fun do_something(owner_cap: &OwnerCap<PROJECT>, roles: &SRoles<PROJECT>, role_cap: &RoleCap<MyOwnRole>, ctx: &mut TxContext) {
    // Check if the sender has the Admin role
    assert!(access_control::has_cap_access<MARKETPLACE, MyOwnRole>(roles, role_cap), ENotAuthorized);
    // Perform the action
    // ...
    }

    public fun revoke_role(owner_cap: &OwnerCap<PROJECT>, roles: &mut SRoles<PROJECT>, role_id: ID, ctx: &mut TxContext) {
    // Remove a role from the system
    access_control::revoke_role_access<PROJECT>(owner_cap, roles, role_id);
    }

}
```

## Contributors 
Contributions are welcome! Feel free to open issues, suggest improvements, or submit pull requests.  

## License
This repository is provided under MIT license. See the LICENSE file for details. You are free to use, modify, and distribute this code for both personal and commercial purposes.
