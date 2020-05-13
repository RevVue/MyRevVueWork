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
@isTest(seeAllData=false)
private class Test_RevRecScheduleSetCntrlCopy {
    /**
 *	Description		:	This class is used to test the functioonality of RevRecScheduleSetControllerCopy.
 *
 *	Created Date	:	07/13/2015
 *
 *	Version			:	V_1.0
 *
 *	Revision Log	:	Created - V_1.0
 *
 *	Coverage		:
**/
	
	/**
	 *	@description	:	This method is used to test the controller functionality.	
	 *
	 *	@args			:	
	 *
	 *	@return			:	void
	**/
    static testMethod void myUnitTest() {
       
       //Dummy test data 
        //Get standard pricbook Id to insert new price booke entery
        Id pricebookId = Test.getStandardPricebookId();
        
        //App Setting Data
        RevRecAppSetting__c appSetting = new RevRecAppSetting__c(Name = 'AppSetting', 
                      									Certain_date_of_month__c = '28', Time_of_Month_Selection_Types_tr__c = '1',
                      									Time_of_Month_Selection_Types__c = '2');
                      
        insert appSetting;
        
        //List of RevRecRules
        List<RevRecRules__c> revRecRules = new List<RevRecRules__c>();
        
        //Add rules into list
        revRecRules.add(new RevRecRules__c(Name = 'Test - Blended - 1', Active__c = true, Divide_By__c = '2', Offset_Period__c = 2,
                                           Offset_Type__c = 'Start',Default_Rule__c = true,
                                           Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION,
                                           Revenue_Recognition_Start_Date__c  = 'OPPORTUNITY:CloseDate'));
        
        revRecRules.add(new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
					                       AppRopozSLN__Offset_Period__c = 2, 
					                       AppRopozSLN__Offset_Type__c = 'Start',
					                       Default_Rule__c = true,
					                       Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE,
					                       Milestone_Type__c =  'amount',  
					                       Revenue_Recognition_End_Date__c = 'OPPORTUNITY:CloseDate',
					                       Revenue_Recognition_Start_Date__c  = 'OPPORTUNITY:CloseDate'));
        
        //Insert RevRecRules                                                          
        insert  revRecRules;
        
        //Test Opportunity
        Opportunity opportynity = new Opportunity(Name = 'Test', CloseDate = Date.Today(), StageName = 'Closed Won',
                    							  Type = 'New Customer');
        //insert opportunity           
        insert opportynity;
        
        //List of Product
        List<Product2> products = new List<Product2>();
        
        //Add products into list
        products.add(new Product2(Name = 'Test0',  IsActive = true, RevRecRule__c = revRecRules[0].Id));
        products.add(new Product2(Name = 'Test1',  IsActive = true, RevRecRule__c = revRecRules[1].Id));
        
        //Insert Product
        insert products;
        System.assertEquals(true,products[0].IsActive);
          
        //Custom price Book
        Pricebook2 customPB = new Pricebook2(Name = 'Test Custom Pricebook', isActive = true);
        insert customPB;
        
        //List of PriceBookEntry
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        
        //Add new pricebook entry in list
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[0].Id, UnitPrice = 8000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        pricebookEntries.add(new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = products[1].Id, UnitPrice = 9000, isActive = true));
        
        //Insert Price book entries
        insert pricebookEntries;
        
        //Opportunity Line Item
        List<OpportunityLineItem> oppLineItems = new List<OpportunityLineItem>();
        
        //Add line item into list
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[1].Id, Quantity = 10, UnitPrice = 10000
        											,ServiceDate = Date.Today().addDays(90)));
        oppLineItems.add(new OpportunityLineItem(OpportunityId = opportynity.Id, PricebookEntryId = pricebookEntries[3].Id, Quantity = 10, UnitPrice = 15000
        											,ServiceDate = Date.Today().addDays(90)));
        
        //Insert Opp Line items
        insert oppLineItems;
         
        //List of RevRecOpportunity Line Items
        List<RevRecOpportunityLineItem__c> revRecLineItems =  new List<RevRecOpportunityLineItem__c>();
        
        //Add RevRec Line items  into list
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
        													 DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        revRecLineItems.add(new RevRecOpportunityLineItem__c(Name = 'Test0', Opportunity__c = opportynity.Id, ResidualAmount__c = 100,
        													 DeferredRev__c = 1200, RecognizedRev__c = 1000));
        
        //Insert RevRec Line Items
        insert revRecLineItems;  
        
        //Update oli
        oppLineItems[0].RevRecOpportunityLineItem__c = revRecLineItems[0].Id;
        oppLineItems[1].RevRecOpportunityLineItem__c = revRecLineItems[1].Id;
        
        //Update line items 
        update oppLineItems;
        
        //Query thriugh RevRec Line item schedule
        AppRopozSLN__RevRecOpportunityLineItemSchedule__c  listRevRecLineItemSch = [SELECT ID, AppRopozSLN__RevRecOpportunityLineItem__c ,
                                                                                                 AppRopozSLN__RecognizedRev__c,
                                                                                                 AppRopozSLN__RecognizedRevTotal__c, 
                                                                                                 AppRopozSLN__ResidualAmountTotal__c,
                                                                                                 AppRopozSLN__OriginalDate__c,
                                                                                                 AppRopozSLN__DeferredRev__c FROM
                                                                                                 AppRopozSLN__RevRecOpportunityLineItemSchedule__c 
                                                                            WHERE AppRopozSLN__RevRecOpportunityLineItem__c =: revRecLineItems[0].Id];
        
        //Assert for results
        system.assertEquals(0.00,listRevRecLineItemSch.AppRopozSLN__ResidualAmountTotal__c);
        
        listRevRecLineItemSch = [SELECT ID, AppRopozSLN__RevRecOpportunityLineItem__c ,
                                                                    AppRopozSLN__RecognizedRev__c,
                                                                    AppRopozSLN__RecognizedRevTotal__c, 
                                                                    AppRopozSLN__ResidualAmountTotal__c,
                                                                    AppRopozSLN__OriginalDate__c,
                                                                    AppRopozSLN__DeferredRev__c FROM
                                                                    AppRopozSLN__RevRecOpportunityLineItemSchedule__c 
                                                                    WHERE AppRopozSLN__RevRecOpportunityLineItem__c =: revRecLineItems[1].Id];
        
        //Calling Opportunity extension page controller 
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(opportynity);
        RevRecOpportunityExtension cExt = new RevRecOpportunityExtension(sc);        
        
        //Calling controller method 
        cExt.ReCalculateAll();
        
        //Set URL parameters
        ApexPages.currentPage().getParameters().put('opportunityId', opportynity.Id);
        
        //Test start here
        Test.startTest();
        
        //Constructer initilization
        RevRecScheduleSetControllerCopy controller = new RevRecScheduleSetControllerCopy();
        
        //Initlize wrapper 
        //RevRecScheduleSetController.revRecScheduleWrapper  wrap = new RevRecScheduleSetController.revRecScheduleWrapper();
        
        //Calling controoller methods
		controller.ExportToExcel();
		PageReference cancelPage = controller.cancel(); 
		Opportunity opp = controller.getOpportunity();
		
		//Assert for results 
		system.assert(cancelPage != null) ;    
        controller.getColors();
        
        RevRecOpportunityLineItemSchedule__c schedule = listRevRecLineItemSch;
        Decimal cumulativeRecognized = 500.00;
        Decimal recognizedWeiCumulative = 300.00 ;
        Decimal forecastedCumulative = 652.00;
        RevRecScheduleSetControllerCopy.RevRecLineItemScheduleWrapper LineItemWrap = new RevRecScheduleSetControllerCopy.RevRecLineItemScheduleWrapper(schedule, cumulativeRecognized, recognizedWeiCumulative, forecastedCumulative);
        
       
		//Test stops here
		Test.stopTest();
    }
}