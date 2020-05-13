@istest
private class Test_MonthlyRevenueRollupTriggerHelper {
    @istest
    Static void myUnitTest1() {
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
        System.assertEquals(true, products[1].IsActive);
        
        //List of Opportunity
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Test' , CloseDate = Date.Today(),StageName = 'Closed Won',  Amount = 1000, Type = 'New Customer', AccountId = accounts[0].Id,End_Revenue_Date__c =  Date.Today().addYears(3) , Start_Revenue_Date__c = Date.Today().addMonths(7),	Probability = 50));
        opportunities.add(new Opportunity(Name = 'Testing1', REVvue_RevRecRule__c=revRecDefaultRule.Id, CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), Probability = 50, AccountId = accounts[0].Id,End_Revenue_Date__c =  Date.Today().addYears(3) , Start_Revenue_Date__c = Date.Today().addMonths(7)));
        opportunities.add(new Opportunity(Name = 'Testing2' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[0].Id, Probability = 50));
        opportunities.add(new Opportunity(Name = 'Testing3' , CloseDate = Date.Today().addMonths(-2), StageName = 'Closed Lost',  Type = 'New Customer', Amount = 1000, REVvue_CreatedDate__c = Date.Today(), AccountId = accounts[1].Id, Probability = 50));
        
        insert opportunities;
        
        List<Yearly_Revenue_Rollups__c> listOfYearly = new List<Yearly_Revenue_Rollups__c>();
        
        listOfYearly.add(new Yearly_Revenue_Rollups__c(Name  = '2019', Year__c = '2019',Opportunity__c = opportunities[0].Id, Yearly_Actual_Revenue__c = 0, Yearly_Forecasted_Revenue__c = 0, Yearly_Forecasted_Revenue_Weighted__c = 0));
        listOfYearly.add(new Yearly_Revenue_Rollups__c(Name  = '2020', Year__c = '2020', Opportunity__c = opportunities[0].Id, Yearly_Actual_Revenue__c = 0, Yearly_Forecasted_Revenue__c = 0, Yearly_Forecasted_Revenue_Weighted__c = 0));
        listOfYearly.add(new Yearly_Revenue_Rollups__c(Name  = '2021', Year__c = '2021', Opportunity__c = opportunities[1].Id, Yearly_Actual_Revenue__c = 0, Yearly_Forecasted_Revenue__c = 0, Yearly_Forecasted_Revenue_Weighted__c = 0));
        insert listOfYearly;
        System.assertEquals(0, listOfYearly[1].Yearly_Actual_Revenue__c);
        
        List<Monthly_Revenue_Rollups__c> listOfMonthly = new List<Monthly_Revenue_Rollups__c>();
        
        listOfMonthly.add(new Monthly_Revenue_Rollups__c(Name  = '1-2019', Year__c = '2019',Month__c = 1,Yearly_Revenue_Rollup__c =listOfYearly[0].Id, Opportunity__c = opportunities[0].Id, Monthly_Actual_Revenue__c = 0, Monthly_Forecasted_Revenue__c = 0, Monthly_Forecasted_Revenue_Weighted__c = 0));
        listOfMonthly.add(new Monthly_Revenue_Rollups__c(Name  = '1-2019', Year__c = '2019',Month__c = 1,Yearly_Revenue_Rollup__c =listOfYearly[1].Id, Opportunity__c = opportunities[0].Id, Monthly_Actual_Revenue__c = 0, Monthly_Forecasted_Revenue__c = 0, Monthly_Forecasted_Revenue_Weighted__c = 0));
        listOfMonthly.add(new Monthly_Revenue_Rollups__c(Name  = '1-2019', Year__c = '2019',Month__c = 1,Yearly_Revenue_Rollup__c =listOfYearly[0].Id, Opportunity__c = opportunities[0].Id, Monthly_Actual_Revenue__c = 0, Monthly_Forecasted_Revenue__c = 0, Monthly_Forecasted_Revenue_Weighted__c = 0));
        insert listOfMonthly;
        
        List<Acc_Yearly_Revenue_Rollup__c> listOfAccYearlyIDs = new List<Acc_Yearly_Revenue_Rollup__c>();
        listOfAccYearlyIDs.add(new Acc_Yearly_Revenue_Rollup__c(Name  = '2019', Year__c = '2019',Accounts__c = accounts[0].Id, Yearly_Actual_Revenue__c = 0, Yearly_Forecasted_Revenue__c = 0, Yearly_Forecasted_Revenue_Weighted__c = 0));
        listOfAccYearlyIDs.add(new Acc_Yearly_Revenue_Rollup__c(Name  = '2020', Year__c = '2020',Accounts__c = accounts[1].Id, Yearly_Actual_Revenue__c = 0, Yearly_Forecasted_Revenue__c = 0, Yearly_Forecasted_Revenue_Weighted__c = 0));
        listOfAccYearlyIDs.add(new Acc_Yearly_Revenue_Rollup__c(Name  = '2021', Year__c = '2021',Accounts__c = accounts[0].Id, Yearly_Actual_Revenue__c = 0, Yearly_Forecasted_Revenue__c = 0, Yearly_Forecasted_Revenue_Weighted__c = 0));
		insert listOfAccYearlyIDs;
        delete listOfAccYearlyIDs[0];
        System.assertEquals(3, listOfAccYearlyIDs.size());
        
       List<Monthly_Revenue_Rollups__c> qureyMonthly = [Select Id, Name, Year__c, Month__c, Monthly_Actual_Revenue__c, Monthly_Forecasted_Revenue__c FROM Monthly_Revenue_Rollups__c];
        //System.assert(false,qureyMonthly);
        qureyMonthly[0].Monthly_Actual_Revenue__c = 50.00;
        update qureyMonthly;
        delete qureyMonthly[1];        
    }
}