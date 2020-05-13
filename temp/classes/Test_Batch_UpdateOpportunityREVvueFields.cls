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
@isTest(seeAllData = false)
private class Test_Batch_UpdateOpportunityREVvueFields {

    /**
*    Description    :		This Test class check functionality batch to update historiacal Opportunities to populate REVvue fields with existing data.
*  
*    Created By     :    
*
*    Created Date   :		09/12/2018
*
*    Version        :		V1.0
*
*    Revisison Log  :		V1.0 - 
*
*    Coverage       :		100%
**/   
    static testMethod void myUnitTest() {
        
        //Default Rule
        RevRecRules__c revRecDefaultRule = new RevRecRules__c(Name = 'Test', Active__c = true, Divide_By__c = '2', 
                                                                    AppRopozSLN__Offset_Period__c = 2,
                                                                    AppRopozSLN__Offset_Type__c = 'Start',
                                                                    Default_Rule__c = true,
                                                                    Recognition_Type__c = 'Milestone');
                                                                    
        insert  revRecDefaultRule;
        
        //List of Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Testing1' , CloseDate = Date.Today(), StageName = 'Closed Won',   Amount = 1000, Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Testing2' , CloseDate = Date.Today(), StageName = 'Closed Won',   Amount = 1000, Type = 'New Customer'));
        insert opportunities;
        
        //Test starts here
        Test.startTest();
        
        Batch_UpdateOpportunityREVvueFields bc = new Batch_UpdateOpportunityREVvueFields();
        Database.executeBatch(bc, 10);
        
        //Test stop here
        Test.stopTest();
        
        //Assert for results
        List<Opportunity> opps = [Select REVvue_TotalResidualwei__c, REVvue_TotalResidual__c, REVVUE_CreatedDate__c FROM Opportunity ORDER By Name];      
        System.assertEquals(null, opps[1].REVvue_TotalResidual__c);
        System.assertEquals(null,opps[0].REVVUE_CreatedDate__c);
        System.assertEquals(null , opps[1].REVvue_TotalResidualwei__c);
    }
}