#[test_only]
module access_controll::access_controll_tests {
    use access_controll::access_controll::{Self as controll, SRoles, AdminCap, OwnerCap};
    use sui::{test_scenario::{Self as scen, begin, end, ctx}, test_utils::assert_eq};

    const OWNER: address = @0xA;
    const ADMIN: address = @0xB;

    #[test]
    fun test_add_admin() {
        // Create a Scenario
        let mut scenario = begin(OWNER);
        controll::new(ctx(&mut scenario));
        scen::next_tx(&mut scenario, OWNER);
        // takes resources
        let mut s_roles: SRoles = scen::take_shared<SRoles>(&scenario);
        let oc: OwnerCap = scen::take_from_address<OwnerCap>(&scenario, OWNER);

        // Perform the operation
        controll::add_admin(&oc, &mut s_roles, ADMIN, ctx(&mut scenario));

        // Return the resources
        scen::return_shared(s_roles);
        scen::return_to_address(OWNER, oc);
        end(scenario);
    }

    #[test]
    fun test_add_user() {
        // Create a Scenario
        let mut scenario = begin(OWNER);
        controll::new(ctx(&mut scenario));
        scen::next_tx(&mut scenario, OWNER);
        // takes resources
        let mut s_roles: SRoles = scen::take_shared<SRoles>(&scenario);
        let oc: OwnerCap = scen::take_from_address<OwnerCap>(&scenario, OWNER);

        // Perform the operation
        controll::add_user(&oc, &mut s_roles, ADMIN, ctx(&mut scenario));

        // Return the resources
        scen::return_shared(s_roles);
        scen::return_to_address(OWNER, oc);
        end(scenario);
    }

    #[test]
    fun test_remove_admin() {
        // Create a Scenario
        let mut scenario = begin(OWNER);
        controll::new(ctx(&mut scenario));
        scen::next_tx(&mut scenario, OWNER);
        // takes resources
        let mut s_roles: SRoles = scen::take_shared<SRoles>(&scenario);
        let oc: OwnerCap = scen::take_from_address<OwnerCap>(&scenario, OWNER);

        controll::add_admin(&oc, &mut s_roles, ADMIN, ctx(&mut scenario));

        scen::next_tx(&mut scenario, ADMIN);
        let adminCap: AdminCap = scen::take_from_address<AdminCap>(&scenario, ADMIN);

        // scen::next_tx(&mut scenario, OWNER);
        let adminCapId: ID = object::id(&adminCap);
        let tructhy_admin = controll::has_admin_access(&s_roles, &adminCap);
        assert_eq(tructhy_admin, true);

        scen::next_tx(&mut scenario, OWNER);
        controll::remove_admin(&oc, &mut s_roles, adminCapId);

        scen::next_tx(&mut scenario, ADMIN);
        let falsy_admin = controll::has_admin_access(&s_roles, &adminCap);
        assert_eq(falsy_admin, false);

        // Return the resources
        scen::return_shared(s_roles);
        scen::return_to_address(OWNER, oc);
        scen::return_to_address(ADMIN, adminCap);
        end(scenario);
    }
}
