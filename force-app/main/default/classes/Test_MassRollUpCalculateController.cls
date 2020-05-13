/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
*
* Unit tests are class methods that verify whether a particular piece
* of code is working properly. Unit test methods take no arguments,
* commit no data to the database, and are flagged with the testMethod
* keyword in the method definition.
*
* All test methods in an organization are executed whenever Apex code is deployed
* to a production organization to confirm correctness, ensure code
* coverage, and prevent regressions. All Apex classes are
* required to have at least 75% code coverage in order to be deployed
* to a production organization. In addition, all triggers must have some code coverage.
* 
* The @isTest class annotation indicates this class only contains test
* methods. Classes defined with the @isTest annotation do not count against
* the organization size limit for all Apex scripts.
*
* See the Apex Language Reference for more information about Testing and Code Coverage.
*/
/**
*   Description     :   This class is used to test the functionality of RevRecScheduleSetControllerCopy.
*
*   Created Date    :   09/29/2016
*
*   Version         :   V_1.0
*
*   Revision Log    :   Created - V_1.0
*
*   Coverage        :
**/
@isTest(seeAllData=false)
private class Test_MassRollUpCalculateController {
    
   /** 
    *   @description    :   This method is used to test the controller functionality.   
    *
    *   @args           :   
    *
    *   @return         :   void
    **/
    
    Static testMethod void myUnitTest() {
        
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //Insert Accounts
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'Test Acc 1'));
        accounts.add(new Account(Name = 'Test Acc 2'));
        insert accounts;
        
        //App Setting Data
        AppRopozSLN__RevRecAppSetting__c appSetting = new AppRopozSLN__RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',
                                                                                           AppRopozSLN__Time_of_Month_Selection_Types_tr__c = '1', Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                                              AppRopozSLN__Offset_Period__c = 2, AppRopozSLN__Offset_Type__c = 'Start', Default_Rule__c = true,
                                                              Recognition_Type__c = 'Amortize');
        
        insert  revRecDefaultRule;
        
        //Insert RevRecProductFamilySetting__c
        RevRecProductFamilySetting__c prodFamilySetting = new RevRecProductFamilySetting__c(Name = 'Family 1', RevRecRule__c = revRecDefaultRule.Id);
        insert prodFamilySetting;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        products.add(new Product2(Name = 'Test1',  IsActive = true, Family='Family 1'));
        insert products;
        
        //List of Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Test' , CloseDate = Date.Today(),StageName = 'Closed Won',  Amount = 1000, Type = 'New Customer', AccountId = accounts[0].Id,End_Revenue_Date__c =  Date.Today().addYears(3) , Start_Revenue_Date__c = Date.Today().addMonths(7), Probability = 50));
        opportunities.add(new Opportunity(Name = 'Testing1', REVvue_RevRecRule__c=revRecDefaultRule.Id, CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), Probability = 50, AccountId = accounts[0].Id,End_Revenue_Date__c =  Date.Today().addYears(3) , Start_Revenue_Date__c = Date.Today().addMonths(7)));
        opportunities.add(new Opportunity(Name = 'Testing2' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id, Probability = 50));
        opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[1].Id, Probability = 50));
        
        insert opportunities;
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 2000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 4000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 7000, isActive = true));
        insert pricebookEntries;
        
        //RevRec Line Items
        List<AppRopozSLN__RevRecOpportunityLineItem__c> revRecLineItems =  new List<AppRopozSLN__RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test0', AppRopozSLN__Opportunity__c = opportunities[0].Id,
                                                                          AppRopozSLN__ResidualAmount__c = 100, AppRopozSLN__DeferredRev__c = 1200, AppRopozSLN__RecognizedRev__c = 1000));
        revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test1', AppRopozSLN__Opportunity__c = opportunities[0].Id,
                                                                          AppRopozSLN__ResidualAmount__c = 100, AppRopozSLN__DeferredRev__c = 1200, AppRopozSLN__RecognizedRev__c = 1000));   
        revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test2', AppRopozSLN__Opportunity__c = opportunities[1].Id,
                                                                          AppRopozSLN__ResidualAmount__c = 100, AppRopozSLN__DeferredRev__c = 1200, AppRopozSLN__RecognizedRev__c = 1000));   
        insert  revRecLineItems;
        
        //Insert Line items
        List<OpportunityLineItem> lineItem = new List<OpportunityLineItem>();
        lineItem.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity=1,  UnitPrice = 10000));
        lineItem.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, PricebookEntryId = pricebookEntries[0].Id, Quantity=1, TotalPrice=1000));
        insert lineItem;
        
        //Insert RevRecOpportunityLineItemSchedule .....
        List<RevRecOpportunityLineItemSchedule__c> RevRecOpportunityLineItemSchedules = new List<RevRecOpportunityLineItemSchedule__c>();
        RevRecOpportunityLineItemSchedules.add(new RevRecOpportunityLineItemSchedule__c(External_OpportunityLineItemId__c = lineItem[0].Id,OpportunityLineItemId__c = lineItem[0].Id,RevRecOpportunityLineItem__c =revRecLineItems[0].Id,Date__c = System.today().addDays(2),RecognizedRev__c = 100.00,RecognizedRevTotal__c = 1000.00,ResidualAmountTotal__c = 300.00,RecRevWei__c = 20.00,ForecastedRev__c = 500.00,ForeRevWei__c = 50.00, Month__c = '1',LineItemAmountTotal__c = 5000.00, DeferredRev__c = 20.00,  Sequence__c= 1, DefReWei__c = 50.00));
        RevRecOpportunityLineItemSchedules.add(new RevRecOpportunityLineItemSchedule__c(External_OpportunityLineItemId__c = lineItem[0].Id,OpportunityLineItemId__c = lineItem[0].Id,RevRecOpportunityLineItem__c =revRecLineItems[0].Id,Date__c = System.today().addDays(2),RecognizedRev__c = 100.00,RecognizedRevTotal__c = 1000.00,ResidualAmountTotal__c = 300.00,RecRevWei__c = 20.00,ForecastedRev__c = 500.00,ForeRevWei__c = 50.00, Month__c = '2',LineItemAmountTotal__c = 5000.00, DeferredRev__c = 20.00,  Sequence__c= 2, DefReWei__c = 50.00));
        RevRecOpportunityLineItemSchedules.add(new RevRecOpportunityLineItemSchedule__c(External_OpportunityLineItemId__c = lineItem[1].Id,OpportunityLineItemId__c = lineItem[1].Id,RevRecOpportunityLineItem__c =revRecLineItems[0].Id,Date__c = System.today().addDays(2),RecognizedRev__c = 100.00,RecognizedRevTotal__c = 1000.00,ResidualAmountTotal__c = 300.00,RecRevWei__c = 20.00,ForecastedRev__c = 500.00,ForeRevWei__c = 50.00, Month__c = '3',LineItemAmountTotal__c = 5000.00, DeferredRev__c = 20.00,  Sequence__c= 3, DefReWei__c = 50.00));
        RevRecOpportunityLineItemSchedules.add(new RevRecOpportunityLineItemSchedule__c(External_OpportunityLineItemId__c = lineItem[0].Id,OpportunityLineItemId__c = lineItem[1].Id,RevRecOpportunityLineItem__c =revRecLineItems[0].Id,Date__c = System.today().addDays(2),RecognizedRev__c = 100.00,RecognizedRevTotal__c = 1000.00,ResidualAmountTotal__c = 300.00,RecRevWei__c = 20.00,ForecastedRev__c = 500.00,ForeRevWei__c = 50.00, Month__c = '1',LineItemAmountTotal__c = 5000.00, DeferredRev__c = 20.00,  Sequence__c= 4, DefReWei__c = 50.00));
        
        //check the size of the List....
        if(RevRecOpportunityLineItemSchedules.size()>0){
            insert RevRecOpportunityLineItemSchedules; 
        }
        
        //Asserts
        system.assertEquals(4, opportunities.size());
        
        //Assert
        System.assertEquals(null, products[1].RevRecRule__c);
        
        //Test starts here
        Test.startTest();
        
        //constructer initilization
        MassRollUpCalculateController controller = new MassRollUpCalculateController();
        controller.selectedYear = '2019';
        controller.IsHavingFiscalYear = true;
        controller.oppTotalOpportunity = '2000';
        controller.oppTotalOpportunityWei = '500';
        controller.oppTotalOpportunityForSingleCurrency = 1300.00;
        controller.oppTotalOpportunityWeiForSingleCurrency = 130.00;
        controller.isHavingPermssion = true;
        controller.theListOfYears = new List<String>{'2019'};
        //Calling controoller methods
        
        PageReference cancelPage = controller.cancel(); 
        
        //Call controller methods
        controller = new MassRollUpCalculateController();
        controller.isMultiCurrencyEnabled = false;
        
        //Call controller methods
        controller = new MassRollUpCalculateController();
        controller.isMultiCurrencyEnabled = true;
        
        //Calling controoller methods
        Opportunity oppr = new Opportunity();
        
        //Assert for results 
        System.assert(cancelPage != null); 
        
        //Update chart preference to 2
        appSetting.Chart_Pref__c = '2';
        update appSetting;
        
        
        //calling methods
        //Query Opportunites that has inserted
        List<Opportunity> queryOpp = [SELECT Id, Name, CreatedDate, CloseDate,Probability, StageName, Amount,AccountId,End_Revenue_Date__c,Start_Revenue_Date__c FROM Opportunity];
        try{
            controller.MassRollupRevenueCalculation(queryOpp);
        }
        catch(Exception e){
            //Handle exception here
        }
        
        
        //Test stop here
        Test.stopTest();                
    }
    
      
   /**
    *   @description    :   This method is used to test the controller functionality.   
    *
    *   @args           :   
    *
    *   @return         :   void
    **/
    
    Static testMethod void myUnitTest1() {
        
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //Insert Accounts
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'Test Acc 1'));
        accounts.add(new Account(Name = 'Test Acc 2'));
        insert accounts;
        
        //App Setting Data
        AppRopozSLN__RevRecAppSetting__c appSetting = new AppRopozSLN__RevRecAppSetting__c(Name = 'AppSetting', Certain_date_of_month__c = '28',
                                                                                           AppRopozSLN__Time_of_Month_Selection_Types_tr__c = '1', Time_of_Month_Selection_Types__c = '2');
        insert appSetting;
        
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                                              AppRopozSLN__Offset_Period__c = 2, AppRopozSLN__Offset_Type__c = 'Start', Default_Rule__c = true,
                                                              Recognition_Type__c = 'Amortize');
        
        insert  revRecDefaultRule;
        
        //Insert RevRecProductFamilySetting__c
        RevRecProductFamilySetting__c prodFamilySetting = new RevRecProductFamilySetting__c(Name = 'Family 1', RevRecRule__c = revRecDefaultRule.Id);
        insert prodFamilySetting;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test0',  IsActive = true));
        products.add(new Product2(Name = 'Test1',  IsActive = true, Family='Family 1'));
        insert products;
        
        //List of Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Test' , CloseDate = Date.Today(),StageName = 'Closed Won',  Amount = 1000, Type = 'New Customer', AccountId = accounts[0].Id,End_Revenue_Date__c =  Date.Today().addYears(3) , Start_Revenue_Date__c = Date.Today().addMonths(7), Probability = 50));
        opportunities.add(new Opportunity(Name = 'Testing1', REVvue_RevRecRule__c=revRecDefaultRule.Id, CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), Probability = 50, AccountId = accounts[0].Id,End_Revenue_Date__c =  Date.Today().addYears(3) , Start_Revenue_Date__c = Date.Today().addMonths(7)));
        opportunities.add(new Opportunity(Name = 'Testing2' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id, Probability = 50));
        opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[1].Id, Probability = 50));
        
        insert opportunities;
        
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //PriceBookEntry Lisst
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 1000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 2000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 4000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 7000, isActive = true));
        insert pricebookEntries;
        
        //RevRec Line Items
        List<AppRopozSLN__RevRecOpportunityLineItem__c> revRecLineItems =  new List<AppRopozSLN__RevRecOpportunityLineItem__c>();
        revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test0', AppRopozSLN__Opportunity__c = opportunities[0].Id,
                                                                          AppRopozSLN__ResidualAmount__c = 100, AppRopozSLN__DeferredRev__c = 1200, AppRopozSLN__RecognizedRev__c = 1000));
        revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test1', AppRopozSLN__Opportunity__c = opportunities[0].Id,
                                                                          AppRopozSLN__ResidualAmount__c = 100, AppRopozSLN__DeferredRev__c = 1200, AppRopozSLN__RecognizedRev__c = 1000));   
        revRecLineItems.add(new AppRopozSLN__RevRecOpportunityLineItem__c( Name = 'Test2', AppRopozSLN__Opportunity__c = opportunities[1].Id,
                                                                          AppRopozSLN__ResidualAmount__c = 100, AppRopozSLN__DeferredRev__c = 1200, AppRopozSLN__RecognizedRev__c = 1000));   
        insert  revRecLineItems;
        
        //Insert Line items
        List<OpportunityLineItem> lineItem = new List<OpportunityLineItem>();
        lineItem.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity=1,  UnitPrice = 10000));
        lineItem.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, PricebookEntryId = pricebookEntries[0].Id, Quantity=1, TotalPrice=1000));
        insert lineItem;
        
        //Insert RevRecOpportunityLineItemSchedule .....
        List<RevRecOpportunityLineItemSchedule__c> RevRecOpportunityLineItemSchedules = new List<RevRecOpportunityLineItemSchedule__c>();
        RevRecOpportunityLineItemSchedules.add(new RevRecOpportunityLineItemSchedule__c(External_OpportunityLineItemId__c = lineItem[0].Id,OpportunityLineItemId__c = lineItem[0].Id,RevRecOpportunityLineItem__c =revRecLineItems[0].Id,Date__c = System.today().addDays(2),RecognizedRev__c = 100.00,RecognizedRevTotal__c = 1000.00,ResidualAmountTotal__c = 300.00,RecRevWei__c = 20.00,ForecastedRev__c = 500.00,ForeRevWei__c = 50.00, Month__c = '1',LineItemAmountTotal__c = 5000.00, DeferredRev__c = 20.00,  Sequence__c= 1, DefReWei__c = 50.00));
        RevRecOpportunityLineItemSchedules.add(new RevRecOpportunityLineItemSchedule__c(External_OpportunityLineItemId__c = lineItem[0].Id,OpportunityLineItemId__c = lineItem[0].Id,RevRecOpportunityLineItem__c =revRecLineItems[0].Id,Date__c = System.today().addDays(2),RecognizedRev__c = 100.00,RecognizedRevTotal__c = 1000.00,ResidualAmountTotal__c = 300.00,RecRevWei__c = 20.00,ForecastedRev__c = 500.00,ForeRevWei__c = 50.00, Month__c = '2',LineItemAmountTotal__c = 5000.00, DeferredRev__c = 20.00,  Sequence__c= 2, DefReWei__c = 50.00));
        RevRecOpportunityLineItemSchedules.add(new RevRecOpportunityLineItemSchedule__c(External_OpportunityLineItemId__c = lineItem[1].Id,OpportunityLineItemId__c = lineItem[1].Id,RevRecOpportunityLineItem__c =revRecLineItems[0].Id,Date__c = System.today().addDays(2),RecognizedRev__c = 100.00,RecognizedRevTotal__c = 1000.00,ResidualAmountTotal__c = 300.00,RecRevWei__c = 20.00,ForecastedRev__c = 500.00,ForeRevWei__c = 50.00, Month__c = '3',LineItemAmountTotal__c = 5000.00, DeferredRev__c = 20.00,  Sequence__c= 3, DefReWei__c = 50.00));
        RevRecOpportunityLineItemSchedules.add(new RevRecOpportunityLineItemSchedule__c(External_OpportunityLineItemId__c = lineItem[0].Id,OpportunityLineItemId__c = lineItem[1].Id,RevRecOpportunityLineItem__c =revRecLineItems[0].Id,Date__c = System.today().addDays(2),RecognizedRev__c = 100.00,RecognizedRevTotal__c = 1000.00,ResidualAmountTotal__c = 300.00,RecRevWei__c = 20.00,ForecastedRev__c = 500.00,ForeRevWei__c = 50.00, Month__c = '1',LineItemAmountTotal__c = 5000.00, DeferredRev__c = 20.00,  Sequence__c= 4, DefReWei__c = 50.00));
        
        //check the size of the List....
        if(RevRecOpportunityLineItemSchedules.size()>0){
            insert RevRecOpportunityLineItemSchedules; 
        }
        
        //Asserts
        system.assertEquals(4, opportunities.size());
        
        //Assert
        System.assertEquals(null, products[1].RevRecRule__c);
        
        //Test starts here
        Test.startTest();
       
        //constructer initilization
        MassRollUpCalculateController controller = new MassRollUpCalculateController();
        
        
        //Calling controoller methods
        
        PageReference cancelPage = controller.cancel(); 
        
        //Call controller methods
        controller = new MassRollUpCalculateController();
        controller.isMultiCurrencyEnabled = false;
        
        //Call controller methods
        controller = new MassRollUpCalculateController();
        controller.isMultiCurrencyEnabled = true;
        
        //Calling controoller methods
        Opportunity oppr = new Opportunity();
        
        //Assert for results 
        System.assert(cancelPage != null); 
        
        //Update chart preference to 2
        appSetting.Chart_Pref__c = '2';
        update appSetting;
        
        String scheduleRecRev = 'Test';
        String scheduleRecRevWei = 'TestOLI';
        String schYear = '2019';
        String month = 'May';
        Date scheduleDate = System.today();
        MassRollUpCalculateController.CurrentFiscalYearMonthlyRecords curntFY = new MassRollUpCalculateController.CurrentFiscalYearMonthlyRecords(scheduleRecRev, scheduleRecRevWei, schYear, month, scheduleDate);
        
        Decimal totalSchRecRev = 100;
        Decimal totalSchRecRevWei = 500;
        String schYear1 = '2019';
        String month1 = 'May';
        Date scheduleDate1 = System.today();
        MassRollUpCalculateController.fiscalYearMonthlyRecordsWithSingleCurrency monthlyFY = new MassRollUpCalculateController.fiscalYearMonthlyRecordsWithSingleCurrency(totalSchRecRev, totalSchRecRevWei, schYear1, month1, scheduleDate1);
        
        String yearValue = '1001';
        Date dateValue = System.today();
        String yearlyActualValue  = '500.00';
        String yearlyForecastedValue = '50.00';
        String yearlyForecastedWeightedvalue = '3000.00' ;
        MassRollUpCalculateController.yearlyWrapper yearlyWrap = new MassRollUpCalculateController.yearlyWrapper(yearValue, dateValue, yearlyActualValue, yearlyForecastedValue, yearlyForecastedWeightedvalue);
        
        Decimal monthValue = 5;
        String yearValue1 = '2019';
        Date dateValue1  = System.today();
        String monthlyActualValue = '50.00';
        String monthlyForecastedValue  = '3000.00' ;
        string monthlyForecastedWeightedvalue = '560.00';
        MassRollUpCalculateController.monthlyWrapper monthlyWrap = new MassRollUpCalculateController.monthlyWrapper(monthValue, yearValue1, dateValue1, monthlyActualValue, monthlyForecastedValue, monthlyForecastedWeightedvalue);
        
        controller.calculationOfFiscalYear(2019,2025);
        try{
            controller.getMonthlyRevnueRollUpAccordingSelectedYear();
        }
        catch(Exception e){
            
        }
        controller.calculateFiscalYear();
        
        //Test stop here
        Test.stopTest();                
    }
   
    /**
    *   @description    :   This method is used to test the controller functionality.   
    *
    *   @args           :   
    *
    *   @return         :   void
    **/
    Static testMethod void testFiscalYear() {
        
        List<Period> pd = new List<Period>();
        pd.add(new Period(Type = 'Year', StartDate = System.today().addMonths(7), EndDate = System.today().addYears(1)));
        pd.add(new Period(Type = 'Year', StartDate = System.today(), EndDate = System.today().addYears(1)));
        System.assertEquals(2, pd.size());
        test.startTest();
        //constructer initilization
        MassRollUpCalculateController controller = new MassRollUpCalculateController();
        controller.calculateFiscalYear();
        test.stopTest();
     }
}