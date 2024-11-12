/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Account_Campaign_JunctionTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Account_Campaign_JunctionTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Account_Campaign_Junction__c());
    }
}