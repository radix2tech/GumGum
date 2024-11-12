/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Whitelist_ClientTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Whitelist_ClientTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Whitelist_Client__c());
    }
}