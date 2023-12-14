@isTest
private class OrderProcessTest {
     @isTest static void testCallout() {
        
        Account acct = new Account(Name='tAccount');
        insert acct;
        Product2 pd = new Product2(Name='Pord A',isActive=true);
        pd.IsActive = true;
        insert pd;
        Id standardPriceBookId = Test.getStandardPricebookId();
        
        Order od = new Order();
        od.Name = '14TPE000001';
        od.AccountId = acct.Id;
        od.EffectiveDate = Date.Today();
        od.Status = 'Draft';
        od.Pricebook2Id=standardPriceBookId;
        insert od;
        
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=standardPriceBookId, Product2Id=pd.Id, UnitPrice=99, isActive=true);
        insert pbe;
        Product2 p2ex = [SELECT Name FROM Product2 WHERE Id = :pd.Id];
        System.assertEquals(pd.Name,p2ex.Name);
        
        OrderItem ordPd = new OrderItem(PriceBookEntryId=pbe.Id, OrderId=od.Id, Quantity=1, UnitPrice=99);
        insert ordPd;
        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
            od.Status='Fulfilled';
            update od;
        Test.stopTest();
        
        System.assertEquals('{"example":"test"}', [select Response__c from CallOutStatus__c limit 1][0].Response__c);
    }
}