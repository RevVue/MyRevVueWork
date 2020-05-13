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
  *     Description     :   This Test class check functionality of massRevenueCalculateController which execute batch for matching critaria         
  *  
  *     Created By      :       
  *
  *     Created Date    :   09/30/2014
  *
  *     Version         :   V1.0
  *
  *     Revisison Log   :   v1.0 - Created
  *
  *     Coverage        :   100%
**/  
@isTest(seeAllData = false)
private class Test_MassRevenueCalculateController {

    static testMethod void myUnitTest() {
    
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
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecDefaultRule.Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true, Family='Family 1'));
        insert products;
        
         //List of Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
            opportunities.add(new Opportunity(Name = 'Test' , CloseDate = Date.Today(),StageName = 'Closed Won',  Amount = 1000, Type = 'New Customer', AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing1', REVvue_RevRecRule__c=revRecDefaultRule.Id, CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing2' ,REVvue_RevRecRule__c=null, CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[1].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[1].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today()));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today()));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today()));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            
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
        lineItem.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity=1, TotalPrice=1000,AppRopozSLN__RevRecRule__c = null));
        lineItem.add(new OpportunityLineItem(OpportunityId = opportunities[2].Id, PricebookEntryId = pricebookEntries[0].Id, Quantity=1, TotalPrice=1000));
        insert lineItem;
        
         //Asserts
         system.assertEquals(14, opportunities.size());
         
        //Test starts here
        Test.startTest();
      
        //Assert
        System.assertEquals(null, products[1].RevRecRule__c);
        
        //constructer initilization
        MassRevenueCalculateController controller = new MassRevenueCalculateController();
        
        //values to opportunity
        controller.opportunity = new Opportunity(Name = 'Test', AccountId = accounts[0].Id, StageName = 'Closed Won', CloseDate = Date.Today().addMonths(-3), 
                                                  Type= 'New Customer', Amount = 900, REVvue_CreatedDate__c = Date.Today().addDays(-1));
                                                  
        controller.opportunity1 =  new Opportunity(Name = 'Test', StageName = 'Closed Won', CloseDate = Date.Today().addDays(2), 
                                                   Type= 'New Customer', Amount = 1100, REVvue_CreatedDate__c = Date.Today().addDays(10));
        
        //calling methods
        controller.searchOppRecordsWithMatchingCreteria();
       
        //Asset for results
        system.assertEquals(1, controller.searchCriteriaOpportunities.size());
        
        // get the list of ApexPages.Message
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        
        System.assertEquals(Label.Batch_Starts_Label, msgList[0].getSummary());
        System.assertEquals(ApexPages.Severity.INFO, msgList[0].getSeverity()); 
        
        //Re-Initilize the opportunity instance
        //values to opportunity
        controller.opportunity =   new Opportunity(Name = 'Test', StageName = 'Qualified', CloseDate = Date.Today().addMonths(-3), 
                                                   Type= 'New Customer', Amount = 900);
        controller.opportunity1 =  new Opportunity(Name = 'Test', StageName = 'Qualified', CloseDate = Date.Today().addDays(2), 
                                                   Type= 'New Customer', Amount = 1100, REVvue_CreatedDate__c = Date.Today().addDays(10));
        
        //calling methods
        controller.searchOppRecordsWithMatchingCreteria();
        List<SelectOption> filterCrt = controller.getFilterCriteria();
        List<SelectOption> searchDate = controller.getSearchDateOptions();
       
        //Asset for results
        system.assertEquals(0, controller.searchCriteriaOpportunities.size());        
        
        // get the list of ApexPages.Message
        msgList = ApexPages.getMessages();
        
        //Assert for results
        System.assertEquals(Label.No_Record_Found_Label, msgList[1].getSummary());
        System.assertEquals(ApexPages.Severity.INFO,msgList[1].getSeverity()); 
        
        //Re-initilize construceter
        //controller = new MassRevenueCalculateController();
        //controller.selectedCriteriaField = '--None--';
        controller.selectedCriteria = 'Custom';
        controller.opportunity.REVvue_CreatedDate__c = Date.Today().addMonths(-3);
        controller.opportunity1.REVvue_CreatedDate__c = Date.Today().addDays(10);
        
        //calling methods
        controller.searchOppRecordsWithMatchingCreteria();
        controller.changeCriteria();
        controller.SetRuleAndRuleAssignmentOnLineItem();
        
        products[1].RevRecRule__c = revRecDefaultRule.Id;
        update products[1];
        
         //Re-initilize construceter
        controller = new MassRevenueCalculateController();
        //controller.selectedCriteriaField = '--None--';
        controller.selectedCriteria = 'THIS_YEAR';
        controller.opportunity.REVvue_CreatedDate__c = Date.Today().addMonths(-3);
        controller.opportunity1.REVvue_CreatedDate__c = Date.Today().addDays(10);
        
        //calling methods
        //controller.searchOppRecordsWithMatchingCreteria();
        controller.changeCriteria();
        controller.SetRuleAndRuleAssignmentOnLineItem();
        
        controller.opportunity1 =  new Opportunity(Name = 'Testing1', REVvue_RevRecRule__c=revRecDefaultRule.Id);
        
        //calling methods
        //controller.searchOppRecordsWithMatchingCreteria();
       
        //Asset for results
        system.assertEquals(0, controller.searchCriteriaOpportunities.size());
        
        controller.SetRuleAndRuleAssignmentOnLineItem();
        
        controller.opportunity =  new Opportunity(Name = 'Test', REVvue_RevRecRule__c=revRecDefaultRule.Id);
        
        //calling methods
        //controller.searchOppRecordsWithMatchingCreteria();
       
        //Asset for results
        system.assertEquals(0, controller.searchCriteriaOpportunities.size());
        
        controller.SetRuleAndRuleAssignmentOnLineItem();
        //Test stop here
        Test.stopTest();                
    }
    
    //For RevRecRollUpCalculateController..
     static testMethod void myUnitTest1() {
    
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
            opportunities.add(new Opportunity(Name = 'Test' , CloseDate = Date.Today(),StageName = 'Closed Won',  Amount = 1000, Type = 'New Customer', AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing1', REVvue_RevRecRule__c=revRecDefaultRule.Id, CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing2' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[1].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[1].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today()));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today()));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today()));
            opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Won',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id));
            
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
        lineItem.add(new OpportunityLineItem(OpportunityId = opportunities[0].Id, PricebookEntryId = pricebookEntries[1].Id, Quantity=1, TotalPrice=1000));
        lineItem.add(new OpportunityLineItem(OpportunityId = opportunities[1].Id, PricebookEntryId = pricebookEntries[0].Id, Quantity=1, TotalPrice=1000));
        insert lineItem;
        
         //Asserts
         system.assertEquals(14, opportunities.size());
         
        //Test starts here
        Test.startTest();
      
        //Assert
        System.assertEquals(null, products[1].RevRecRule__c);
        
        //constructer initilization
        RevRecRollupCalculateController controller = new RevRecRollupCalculateController();
        try{
        //values to opportunity
        controller.opportunity = new Opportunity(Name = 'Test',  StageName = 'Closed Won', CloseDate = Date.Today(), 
                                                  Type= 'New Customer', Amount = 900);
                                                  
        controller.opportunity1 =  new Opportunity(Name = 'Test', StageName = 'Closed Won', CloseDate = Date.Today(), 
                                                   Type= 'New Customer', Amount = 1100, REVvue_CreatedDate__c = Date.Today().addDays(10));
		
        
        //calling methods
         
        //controller.SetYearlyAndMonthlyRollupOnOpportunity();
         }
         catch(Exception e){
             
         }
       
        //Asset for results
        system.assertEquals(0, controller.searchCriteriaOpportunities.size());
        
        // get the list of ApexPages.Message
        List<ApexPages.Message> msgList = ApexPages.getMessages();
        
        //System.assertEquals(Label.Batch_Starts_Label, msgList[0].getSummary());
        //System.assertEquals(ApexPages.Severity.INFO, msgList[0].getSeverity()); 
        
        //Re-Initilize the opportunity instance
        //values to opportunity
        controller.opportunity =   new Opportunity(Name = 'Test', StageName = 'Qualified', CloseDate = Date.Today(), 
                                                   Type= 'New Customer', Amount = 900);
        controller.opportunity1 =  new Opportunity(Name = 'Test', StageName = 'Qualified', CloseDate = Date.Today(), 
                                                   Type= 'New Customer', Amount = 1100, REVvue_CreatedDate__c = Date.Today().addDays(10));
        
        //calling methods
        controller.SetYearlyAndMonthlyRollupOnOpportunity();
        List<SelectOption> filterCrt = controller.getFilterCriteria();
        List<SelectOption> searchDate = controller.getSearchDateOptions();
       
        //Asset for results
        system.assertEquals(0, controller.searchCriteriaOpportunities.size());        
        
        // get the list of ApexPages.Message
        msgList = ApexPages.getMessages();
        
        //Assert for results
        System.assertEquals(Label.No_Record_Found_Label, msgList[0].getSummary());
        System.assertEquals(ApexPages.Severity.INFO,msgList[0].getSeverity()); 
        
        //Re-initilize construceter
        //controller = new MassRevenueCalculateController();
        //controller.selectedCriteriaField = '--None--';
        controller.selectedCriteria = 'Custom';
        controller.opportunity.REVvue_CreatedDate__c = Date.Today().addMonths(-3);
        controller.opportunity1.REVvue_CreatedDate__c = Date.Today().addDays(10);
        controller.opportunity.CloseDate = Date.Today().addMonths(-3);
        controller.opportunity1.CloseDate = Date.Today().addDays(10);
        
        //calling methods
        controller.SetYearlyAndMonthlyRollupOnOpportunity();
        controller.changeCriteria();
        
        products[1].RevRecRule__c = revRecDefaultRule.Id;
        update products[1];
        
         //Re-initilize construceter
        controller = new RevRecRollupCalculateController();
        //controller.selectedCriteriaField = '--None--';
        controller.selectedCriteria = 'THIS_YEAR';
        controller.opportunity.REVvue_CreatedDate__c = Date.Today().addMonths(-3);
        controller.opportunity1.REVvue_CreatedDate__c = Date.Today().addDays(10);
        controller.opportunity.CloseDate = Date.Today().addMonths(-3);
        controller.opportunity1.CloseDate = Date.Today().addDays(10);
         
        //calling methods
        //controller.searchOppRecordsWithMatchingCreteria();
        controller.changeCriteria();
        
        controller.opportunity1 =  new Opportunity(Name = 'Testing1', REVvue_RevRecRule__c=revRecDefaultRule.Id ,CloseDate = System.today());
        
        //calling methods
        //controller.searchOppRecordsWithMatchingCreteria();
       
        //Asset for results
        system.assertEquals(0, controller.searchCriteriaOpportunities.size());
        
        controller.opportunity =  new Opportunity(Name = 'Test', REVvue_RevRecRule__c=revRecDefaultRule.Id , CloseDate = System.today());
        
        //calling methods
        //controller.searchOppRecordsWithMatchingCreteria();
       
        //Asset for results
        system.assertEquals(0, controller.searchCriteriaOpportunities.size());
        
        //Test stop here
        Test.stopTest();                
    }
}