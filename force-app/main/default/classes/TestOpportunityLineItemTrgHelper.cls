/* Test Class for OpportunityLineItemTrgHelper
* Ankita Goel, 1/18/18*/

@isTest
Public class TestOpportunityLineItemTrgHelper{

    //Test Scenario of Inserting one opportunity and 3 opportunity line items 
    static testMethod void testMethod1() {
        Trigger_Setting__c tsOppLineItem = new Trigger_Setting__c();
        tsOppLineItem.Object_Name__c   = 'OpportunityLineItem';
        tsOppLineItem.After_Insert__c = true;
        tsOppLineItem.After_Update__c = true;
        tsOppLineItem.After_Delete__c = true;
        tsOppLineItem.Name             = 'OpportunityLineItem';
        insert tsOppLineItem;
        
        Account testAcc = new Account(name = 'TestAcc');
        insert testAcc;
        Id pricebookId = Test.getStandardPricebookId();

        Product2 prd1 = new Product2 (Name='Test Product Entry 1',Description='Test Product Entry 1',productCode = 'ABC', isActive = true);
        insert prd1;
        
        PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=pricebookId,UnitPrice=50, isActive=true);
        insert pbe1;
        
        Opportunity opp = new Opportunity(AccountId= testAcc.id,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp',CloseDate= System.Today()+ 3 ,Pricebook2Id = pbe1.Pricebook2Id, StageName ='Initial call' );
        insert opp;

        OpportunityLineItem opl1 = new OpportunityLineItem(OpportunityId= opp.id,Start_Date__c =  System.Today()-20,End_Date__c =System.Today()+ 10,PriceBookEntryID=pbe1.id,Quantity=1,TotalPrice= 50 ) ;
        OpportunityLineItem opl2 = new OpportunityLineItem(OpportunityId= opp.id,Start_Date__c =  System.Today(),End_Date__c =System.Today()+ 10,PriceBookEntryID=pbe1.id,Quantity=1,TotalPrice= 50 ) ;

        List<OpportunityLineItem > listOppLineItem = new List<OpportunityLineItem >();
        listOppLineItem.add(opl1);
        listOppLineItem.add(opl2 );
         Test.startTest();
        insert(listOppLineItem);
        delete listOppLineItem;
        Test.stopTest();
        Opportunity opp1 = [Select id , Start_date__c, End_Date__c from Opportunity where id =:opp.id];
		
      //  System.assertEquals(opp1.Start_Date__c,System.Today()-20); 
       // System.assertEquals(opp1.End_Date__c,System.Today()+ 100);
        
    }


    //Test Scenario of Inserting 100 opportunities and 10 opportunity line items for each Oppotunity
    static testMethod void testMethod2() {
        Trigger_Setting__c tsOppLineItem = new Trigger_Setting__c();
        tsOppLineItem.Object_Name__c   = 'OpportunityLineItem';
        tsOppLineItem.After_Insert__c = true;
        tsOppLineItem.After_Update__c = true;
        tsOppLineItem.After_Delete__c = true;
        tsOppLineItem.Name             = 'OpportunityLineItem';
        insert tsOppLineItem;
        Account testAcc = new Account(name = 'TestAcc');
        insert testAcc;
        Id pricebookId = Test.getStandardPricebookId();

        Product2 prd1 = new Product2 (Name='Test Product Entry 1',Description='Test Product Entry 1',productCode = 'ABC', isActive = true);
        insert prd1;
        
        PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=pricebookId,UnitPrice=50, isActive=true);
        insert pbe1;
        List<Opportunity> listOpp = new List<Opportunity>();
        List<OpportunityLineItem > listOppLineItem = new List<OpportunityLineItem >();
        Set<id> setOpplineItemId = new Set<id>();
        for(integer i=0;i<10;i++){
            Opportunity opp = new Opportunity(name = 'Test Opp'+i,Agency_Name__c=testAcc.id,AccountId= testAcc.id,Start_Date__c = System.Today()-i-10,End_Date__c =System.Today()+i+10 ,CloseDate= System.Today()+ 3 ,Pricebook2Id = pbe1.Pricebook2Id, StageName ='Initial call' );
            listOpp.add(opp);
        }
        insert listOpp;
        Test.startTest();
        for(Opportunity opp : listOpp){
            for(integer j=0;j<10;j++){
                OpportunityLineItem opl1 = new OpportunityLineItem(OpportunityId= opp.id,Start_Date__c =  System.Today()-j-20,End_Date__c =System.Today()+j+ 20,PriceBookEntryID=pbe1.id,Quantity=1,TotalPrice= 50 ) ;
                listOppLineItem.add(opl1);
                setOpplineItemId .add(opl1.id);
            }

        }  
        insert listOppLineItem; 
        Test.stopTest(); 
        
        
       // Opportunity opp1 = [Select id , Start_date__c, End_Date__c from Opportunity where name ='Test Opp0'];

       // System.assertEquals(opp1.Start_Date__c,System.Today()-29); 
       // System.assertEquals(opp1.End_Date__c,System.Today()+ 29);
                  
        
    }
    
    // Test Scenario of updating the Opp Line Items
    static testMethod void testMethod3() {
        Trigger_Setting__c tsOppLineItem = new Trigger_Setting__c();
        tsOppLineItem.Object_Name__c   = 'OpportunityLineItem';
        tsOppLineItem.After_Insert__c = true;
        tsOppLineItem.After_Update__c = true;
        tsOppLineItem.After_Delete__c = true;
        tsOppLineItem.Name             = 'OpportunityLineItem';
        insert tsOppLineItem;
        Account testAcc = new Account(name = 'TestAcc');
        insert testAcc;
        Id pricebookId = Test.getStandardPricebookId();

        Product2 prd1 = new Product2 (Name='Test Product Entry 1',Description='Test Product Entry 1',productCode = 'ABC', isActive = true);
        insert prd1;
        
        PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=pricebookId,UnitPrice=50, isActive=true);
        insert pbe1;
        
        Opportunity opp = new Opportunity(AccountId= testAcc.id,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp',CloseDate= System.Today()+ 3 ,Pricebook2Id = pbe1.Pricebook2Id, StageName ='Initial call' );
        insert opp;

        OpportunityLineItem opl1 = new OpportunityLineItem(OpportunityId= opp.id,Start_Date__c =  System.Today()-20,End_Date__c =System.Today()+ 10,PriceBookEntryID=pbe1.id,Quantity=1,TotalPrice= 50 ) ;
        OpportunityLineItem opl2 = new OpportunityLineItem(OpportunityId= opp.id,Start_Date__c =  System.Today(),End_Date__c =System.Today()+ 10,PriceBookEntryID=pbe1.id,Quantity=1,TotalPrice= 50 ) ;

        List<OpportunityLineItem > listOppLineItem = new List<OpportunityLineItem >();
        listOppLineItem.add(opl1);
        listOppLineItem.add(opl2 );
        Test.startTest();
        insert(listOppLineItem);
        opl1.Start_Date__c =  System.Today()-50;
        opl1.End_Date__c =  System.Today()+50;
        update opl1;
        Test.stopTest();

        Opportunity opp1 = [Select id , Start_date__c, End_Date__c from Opportunity where id =:opp.id];
       // System.assertEquals(opp1.Start_Date__c,System.Today()-50); 
       // System.assertEquals(opp1.End_Date__c,System.Today()+ 100);
        
    }
    
}