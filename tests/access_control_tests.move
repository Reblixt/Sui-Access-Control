#[test_only]
module access_control::access_control_tests {
    use access_control::access_control::{
        Self as controll,
        SRoles,
        RoleCap,
        OwnerCap,
        init_test,
        ACCESS_CONTROL
    };
    use sui::{test_scenario::{Self as scen, begin, end, ctx}, test_utils::assert_eq};

    const OWNER: address = @0xA;
    const ADMIN: address = @0xB;

    // public struct ACCESS_CONTROL has drop {}

    public struct AdminRole has key {
        id: UID,
    }

    // public struct Owner has key {
    //     id: UID,
    // }

    #[test]
    fun test_add_admin() {
        // Create a Scenario
        let mut scenario = begin(OWNER);
        init_test(scenario.ctx());
        // controll::new<ACCESS_CONTROL>(otw, ctx(&mut scenario));
        scen::next_tx(&mut scenario, OWNER);
        // takes resources
        let mut s_roles: SRoles<ACCESS_CONTROL> = scen::take_shared<SRoles<ACCESS_CONTROL>>(
            &scenario,
        );
        let oc: OwnerCap<ACCESS_CONTROL> = scen::take_from_address<OwnerCap<ACCESS_CONTROL>>(
            &scenario,
            OWNER,
        );

        // Perform the operation
        controll::add_role<ACCESS_CONTROL, AdminRole>(
            &oc,
            &mut s_roles,
            ADMIN,
            ctx(&mut scenario),
        );

        // Return the resources
        scen::return_shared(s_roles);
        scen::return_to_address(OWNER, oc);
        end(scenario);
    }

    #[test]
    fun test_remove_role() {
        // Create a Scenario
        let mut scenario = begin(OWNER);
        init_test(scenario.ctx());
        // let otw = ACCESS_CONTROL {};
        // controll::new<ACCESS_CONTROL>(otw, ctx(&mut scenario));
        scen::next_tx(&mut scenario, OWNER);
        // takes resources
        let mut s_roles: SRoles<ACCESS_CONTROL> = scen::take_shared<SRoles<ACCESS_CONTROL>>(
            &scenario,
        );
        let oc: OwnerCap<ACCESS_CONTROL> = scen::take_from_address<OwnerCap<ACCESS_CONTROL>>(
            &scenario,
            OWNER,
        );

        controll::add_role<ACCESS_CONTROL, AdminRole>(
            &oc,
            &mut s_roles,
            ADMIN,
            ctx(&mut scenario),
        );

        scen::next_tx(&mut scenario, ADMIN);
        let adminCap = scen::take_from_address<RoleCap<AdminRole>>(&scenario, ADMIN);

        // scen::next_tx(&mut scenario, OWNER);
        let adminCapId: ID = object::id(&adminCap);
        let tructhy_admin = controll::has_cap_access<ACCESS_CONTROL, AdminRole>(
            &s_roles,
            &adminCap,
        );
        assert_eq(tructhy_admin, true);

        scen::next_tx(&mut scenario, OWNER);
        controll::revoke_role_access(&oc, &mut s_roles, adminCapId, ctx(&mut scenario));

        scen::next_tx(&mut scenario, ADMIN);
        let falsy_admin = controll::has_cap_access<ACCESS_CONTROL, AdminRole>(
            &s_roles,
            &adminCap,
        );
        assert_eq(falsy_admin, false);

        // Return the resources
        scen::return_shared(s_roles);
        scen::return_to_address(OWNER, oc);
        scen::return_to_address(ADMIN, adminCap);
        end(scenario);
    }

    #[test]
    fun test_delete_role() {
        let mut scenario = begin(OWNER);
        init_test(scenario.ctx());
        scen::next_tx(&mut scenario, OWNER);
        // takes resources
        let mut s_roles: SRoles<ACCESS_CONTROL> = scen::take_shared<SRoles<ACCESS_CONTROL>>(
            &scenario,
        );
        let oc: OwnerCap<ACCESS_CONTROL> = scen::take_from_address<OwnerCap<ACCESS_CONTROL>>(
            &scenario,
            OWNER,
        );

        controll::add_role<ACCESS_CONTROL, AdminRole>(
            &oc,
            &mut s_roles,
            ADMIN,
            ctx(&mut scenario),
        );

        scen::next_tx(&mut scenario, ADMIN);
        let adminCap = scen::take_from_address<RoleCap<AdminRole>>(&scenario, ADMIN);

        scen::next_tx(&mut scenario, OWNER);
        let tructhy_admin = controll::has_cap_access<ACCESS_CONTROL, AdminRole>(
            &s_roles,
            &adminCap,
        );
        assert_eq(tructhy_admin, true);

        scen::next_tx(&mut scenario, OWNER);

        controll::delete_cap(&mut s_roles, adminCap, ctx(&mut scenario));

        // Return the resources
        scen::return_shared(s_roles);
        scen::return_to_address(OWNER, oc);
        // scen::return_to_address(ADMIN, adminCap);
        end(scenario);
    }
}
