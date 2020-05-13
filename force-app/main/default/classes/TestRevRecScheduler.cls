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
@isTest(SeeAllData=false)
private class TestRevRecScheduler {
/**
 *  Description     :   Test class for RevRecScheduler.
 *
 *  Created Date    :   
 *
 *  Version         :   V_1.0
 *
 *  Revision Log    :   V_1.0
 *
 *  Coverage        :   
 *
**/
    /**
     *  @description    :   This method is used to test the functionality of RevRecScheduler.
    **/
    static testMethod void test() {
        
        //Test data of opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Test 1', CloseDate = Date.Today().addDays(1), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 2', CloseDate = Date.Today().addDays(2), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 3', CloseDate = Date.Today().addDays(3), StageName = 'Open', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 4', CloseDate = Date.Today().addDays(4), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 5', CloseDate = Date.Today().addDays(4), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 6', CloseDate = Date.Today().addDays(4), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 7', CloseDate = Date.Today().addDays(4), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 8', CloseDate = Date.Today().addDays(2), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 9', CloseDate = Date.Today().addDays(3), StageName = 'Open', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 10', CloseDate = Date.Today().addDays(4), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 11', CloseDate = Date.Today().addDays(4), StageName = 'Closed Won', Type = 'New Customer'));
        opportunities.add(new Opportunity(Name = 'Test 12', CloseDate = Date.Today().addDays(4), StageName = 'Closed Won', Type = 'New Customer'));
        //opportunities.add(new Opportunity(Name = 'Test 13', CloseDate = Date.Today().addDays(4), StageName = 'Closed Won', Type = 'New Customer'));
        
        insert opportunities;
        
        //Test data of RevRecJob
        List<RevRecJob__c> revRecJobs = new List<RevRecJob__c>();
        revRecJobs.add(new RevRecJob__c(Name = 'test job 1', OpportunityID__c = opportunities[0].Id, status_date__c = Date.today()));
        revRecJobs.add(new RevRecJob__c(Name = 'test job 2', OpportunityID__c = opportunities[1].Id, status_date__c = Date.today()));
        revRecJobs.add(new RevRecJob__c(Name = 'test job 2', OpportunityID__c = opportunities[2].Id, status_date__c = Date.today()));
        insert revRecjobs;
        
        //Test start
        Test.startTest();
        
        String jobId = System.schedule('RevRec Schedule Test', RevRecScheduler.CRON_EXP, new RevRecScheduler());
        
        //Test stop
        Test.stopTest();
        
        //Assert for result
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(RevRecScheduler.CRON_EXP, ct.CronExpression);
        System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime));
    }
}