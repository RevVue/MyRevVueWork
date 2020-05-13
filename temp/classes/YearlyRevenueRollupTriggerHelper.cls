/**
*  Description     :   This is the helper class for Yearly Revenue Rollup Trigger.
*
*  Created Date    :   02/07/2020
*
*  Created By      :   Bill Feeheley
*
*  Version         :   V_1.0
**/
public without sharing class YearlyRevenueRollupTriggerHelper {
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldAccYearlyResult = Utility.getFieldPermissions('Acc_Yearly_Revenue_Rollup__c');
    
    
    /**
    *  @description    :   This method is used to calculate yearly rollup on account and handle insert, update and delete case also.    
    *
    *  @args           :   Trigger.New
    *
    *  @return         :   
    **/
    public static void calculateAccYearlyRollupOnAccount(List<Yearly_Revenue_Rollups__c> newYearlyRevenueRollup, Map<Id, Yearly_Revenue_Rollups__c> oldMapOfYearlyRevenueRollup) {
        Set<Id> oppIds = new Set<Id>();
        Id accountId ;
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        Account theAccount = new Account();
        
        for(Yearly_Revenue_Rollups__c newYearly : newYearlyRevenueRollup) {
            if((oldMapOfYearlyRevenueRollup == null 
                || oldMapOfYearlyRevenueRollup.get(newYearly.Id).Yearly_Forecasted_Revenue_Weighted__c != newYearly.Yearly_Forecasted_Revenue_Weighted__c
                || oldMapOfYearlyRevenueRollup.get(newYearly.Id).Yearly_Forecasted_Revenue__c != newYearly.Yearly_Forecasted_Revenue__c
                || oldMapOfYearlyRevenueRollup.get(newYearly.Id).Yearly_Actual_Revenue__c != newYearly.Yearly_Actual_Revenue__c
                || oldMapOfYearlyRevenueRollup.get(newYearly.Id).Year__c != newYearly.Year__c
                || oldMapOfYearlyRevenueRollup.get(newYearly.Id).Yearly_Revenue_Date__c != newYearly.Yearly_Revenue_Date__c
                || oldMapOfYearlyRevenueRollup.get(newYearly.Id).Opportunity__c != newYearly.Opportunity__c)){
                    
                    oppIds.add(newYearly.Opportunity__c);
                }
        }
        
        if(oppIds.size() > 0 ) { 
            for(Yearly_Revenue_Rollups__c yearly :[Select Id, Name,  Opportunity__c, Opportunity__r.AccountId 
                                                   From Yearly_Revenue_Rollups__c 
                                                   Where Opportunity__c IN : oppIds AND Opportunity__r.AccountId != null
                                                   Order By Name LIMIT 1]) 
            {
                accountId = yearly.Opportunity__r.AccountId;
            }
        }
        
        String queryAcc = '';
        if(accountId != null) {
            if(!isMultiCurrencyEnabled)
                queryAcc += 'SELECT Id, name FROM Account WHERE Id = \''+ accountId +'\' LIMIT 1 ';
            else
                queryAcc += 'SELECT Id, name, CurrencyIsoCode FROM Account WHERE Id = \''+ accountId +'\' LIMIT 1 ';
        }
        
        //Database.query for Account
        if(String.isNotEmpty(queryAcc))
            theAccount = Database.query(queryAcc); 
        
        Map<String, Yearly_Revenue_Rollups__c> mapOfYearWithYearlyRevenueRollups = new Map<String, Yearly_Revenue_Rollups__c>();
        if(accountId != null) {
            for(Yearly_Revenue_Rollups__c yearly :[Select Id, Name, Year__c, Yearly_Revenue_Date__c, Opportunity__c, Opportunity__r.AccountId, Yearly_Actual_Revenue__c, Yearly_Forecasted_Revenue__c, Yearly_Forecasted_Revenue_Weighted__c 
                                                   From Yearly_Revenue_Rollups__c 
                                                   Where Opportunity__r.AccountId =: accountId And Opportunity__r.AccountId != null
                                                   Order By Name]) 
            {
                String mapKey = accountId + '-' + String.valueOf(yearly.Year__c);
                
                if(mapOfYearWithYearlyRevenueRollups.containsKey(mapKey)) {
                    Yearly_Revenue_Rollups__c existingYearlyRollup = mapOfYearWithYearlyRevenueRollups.get(MapKey);
                    
                    existingYearlyRollup.Year__c = yearly.Year__c;
                    existingYearlyRollup.Yearly_Revenue_Date__c = yearly.Yearly_Revenue_Date__c;
                    if(yearly.Yearly_Actual_Revenue__c != null && existingYearlyRollup.Yearly_Actual_Revenue__c != null)
                        existingYearlyRollup.Yearly_Actual_Revenue__c += yearly.Yearly_Actual_Revenue__c;
                    existingYearlyRollup.Yearly_Forecasted_Revenue__c += yearly.Yearly_Forecasted_Revenue__c;
                    existingYearlyRollup.Yearly_Forecasted_Revenue_Weighted__c += yearly.Yearly_Forecasted_Revenue_Weighted__c;
                } else {
                    mapOfYearWithYearlyRevenueRollups.put(mapKey, yearly);
                }
            }
        } 
        
        Map<String, List<Yearly_Revenue_Rollups__c>> mapOfAccIdWithYearWithYearlyRollups = new Map<String, List<Yearly_Revenue_Rollups__c>>();
        for(String acctId : mapOfYearWithYearlyRevenueRollups.keyset()) {
            if(!mapOfAccIdWithYearWithYearlyRollups.containsKey(acctId)) 
                mapOfAccIdWithYearWithYearlyRollups.put(acctId, new List<Yearly_Revenue_Rollups__c>());
            mapOfAccIdWithYearWithYearlyRollups.get(acctId).add(mapOfYearWithYearlyRevenueRollups.get(acctId));
        }
        
        Map<String, List<Acc_Yearly_Revenue_Rollup__c>> mapOfAccIdWithYearWithAccYearlyRollup = new Map<String, List<Acc_Yearly_Revenue_Rollup__c>>();
        for(Acc_Yearly_Revenue_Rollup__c accYearlyRollup : [Select Id, Name, Year__c, Yearly_Revenue_Date__c, Accounts__c, Yearly_Actual_Revenue__c, Yearly_Forecasted_Revenue__c, Yearly_Forecasted_Revenue_Weighted__c 
                                                            From Acc_Yearly_Revenue_Rollup__c 
                                                            Where Accounts__c =: accountId]) 
        {
            if(!mapOfAccIdWithYearWithAccYearlyRollup.containsKey(accYearlyRollup.Accounts__c+'-'+accYearlyRollup.Year__c)) 
                mapOfAccIdWithYearWithAccYearlyRollup.put(accYearlyRollup.Accounts__c+'-'+accYearlyRollup.Year__c, new List<Acc_Yearly_Revenue_Rollup__c>());
            mapOfAccIdWithYearWithAccYearlyRollup.get(accYearlyRollup.Accounts__c+'-'+accYearlyRollup.Year__c).add(accYearlyRollup);
        }
        
        List<Acc_Yearly_Revenue_Rollup__c> accYearlyRollupToBeUpdate = new List<Acc_Yearly_Revenue_Rollup__c>();
        List<Acc_Yearly_Revenue_Rollup__c> listOfAccYearlyIDs = new List<Acc_Yearly_Revenue_Rollup__c>();
        
        if(mapOfAccIdWithYearWithAccYearlyRollup.size() > 0) {
            for(String mapkey : mapOfAccIdWithYearWithAccYearlyRollup.Keyset()) {
                listOfAccYearlyIDs.addAll(mapOfAccIdWithYearWithAccYearlyRollup.get(mapkey));
            } 
        }
        
        for(String accId : mapOfAccIdWithYearWithYearlyRollups.Keyset()) {
            for(Yearly_Revenue_Rollups__c yearly : mapOfAccIdWithYearWithYearlyRollups.get(accId)) {
                if(listOfAccYearlyIDs.size() > 0) {
                    Acc_Yearly_Revenue_Rollup__c accYearlyRollup = new Acc_Yearly_Revenue_Rollup__c(Id = listOfAccYearlyIDs[0].Id, 
                                                                                                    Yearly_Actual_Revenue__c  = null,
                                                                                                    Yearly_Forecasted_Revenue__c = 0,
                                                                                                    Yearly_Forecasted_Revenue_Weighted__c = 0);
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Name',Constants.PERMISSION_UPSERT))
                        accYearlyRollup.Name = yearly.Name;
                    
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Accounts__c',Constants.PERMISSION_UPSERT))
                        accYearlyRollup.Accounts__c = accId.split('-')[0];
                    
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Year__c',Constants.PERMISSION_UPSERT))
                        accYearlyRollup.Year__c = yearly.Year__c;
                    
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Yearly_Revenue_Date__c',Constants.PERMISSION_UPSERT))
                        accYearlyRollup.Yearly_Revenue_Date__c = yearly.Yearly_Revenue_Date__c;
                    
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Yearly_Actual_Revenue__c',Constants.PERMISSION_UPSERT)) {   
                           if(yearly.Yearly_Actual_Revenue__c != null) 
                               accYearlyRollup.Yearly_Actual_Revenue__c = yearly.Yearly_Actual_Revenue__c;
                       }
                    
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Yearly_Forecasted_Revenue__c',Constants.PERMISSION_UPSERT))
                        accYearlyRollup.Yearly_Forecasted_Revenue__c = yearly.Yearly_Forecasted_Revenue__c;
                    
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Yearly_Forecasted_Revenue_Weighted__c',Constants.PERMISSION_UPSERT))        
                        accYearlyRollup.Yearly_Forecasted_Revenue_Weighted__c = yearly.Yearly_Forecasted_Revenue_Weighted__c;
                    
                    if(isMultiCurrencyEnabled)
                        accYearlyRollup.put('CurrencyIsoCode', theAccount.get('CurrencyIsoCode'));
                    
                    if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'Acc_Yearly_Revenue_Rollup__c'))
                        accYearlyRollupToBeUpdate.add(accYearlyRollup);
                    
                    listOfAccYearlyIDs.remove(0);
                    
                } else {
                    Acc_Yearly_Revenue_Rollup__c accYearlyRollup = new Acc_Yearly_Revenue_Rollup__c();                     
                    
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Name',Constants.PERMISSION_UPSERT))
                        accYearlyRollup.Name = yearly.Name;
                    
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Accounts__c',Constants.PERMISSION_UPSERT))
                        accYearlyRollup.Accounts__c = accId.split('-')[0];
                    
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Year__c',Constants.PERMISSION_UPSERT))
                        accYearlyRollup.Year__c = yearly.Year__c;
                    
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Yearly_Revenue_Date__c',Constants.PERMISSION_UPSERT))
                        accYearlyRollup.Yearly_Revenue_Date__c = yearly.Yearly_Revenue_Date__c;
                    
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Yearly_Actual_Revenue__c',Constants.PERMISSION_UPSERT)) {
                        if(yearly.Yearly_Actual_Revenue__c != null)
                            accYearlyRollup.Yearly_Actual_Revenue__c = yearly.Yearly_Actual_Revenue__c;
                    }
                    
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Yearly_Forecasted_Revenue__c',Constants.PERMISSION_UPSERT))
                        accYearlyRollup.Yearly_Forecasted_Revenue__c = yearly.Yearly_Forecasted_Revenue__c;
                    
                    if(Utility.checkFieldPermission(mapfieldAccYearlyResult,'Yearly_Forecasted_Revenue_Weighted__c',Constants.PERMISSION_UPSERT))
                        accYearlyRollup.Yearly_Forecasted_Revenue_Weighted__c = yearly.Yearly_Forecasted_Revenue_Weighted__c;
                    
                    if(isMultiCurrencyEnabled)
                        accYearlyRollup.put('CurrencyIsoCode', theAccount.get('CurrencyIsoCode'));
                    
                    if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'Acc_Yearly_Revenue_Rollup__c'))
                        accYearlyRollupToBeUpdate.add(accYearlyRollup);
                }
            }
        }
        
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'Acc_Yearly_Revenue_Rollup__c')){
               if(accYearlyRollupToBeUpdate.size() > 0 )
                   upsert accYearlyRollupToBeUpdate;
           }
    }
    
    /**
    *  @description    :   This method is used to delete yearly rollup on account    
    *
    *  @args           :   Trigger.New
    *
    *  @return         :   
    **/
    public static void deleteAccYearlyRollups(Map<Id, Yearly_Revenue_Rollups__c> oldMapOfYearlyRevenueRollup) {
        Set<Id> opptIds = new Set<Id>();
        Set<Id> acctIds = new Set<Id>();
        
        if(oldMapOfYearlyRevenueRollup != null) {
            for(Id yearlyId : oldMapOfYearlyRevenueRollup.keyset()){
                opptIds.add(oldMapOfYearlyRevenueRollup.get(yearlyId).Opportunity__c);
            }
        }
       
        if(opptIds.size() > 0 ) { 
            for(Opportunity oppty :[Select Id, Name, AccountId From Opportunity Where Id IN : opptIds]) 
            {
                acctIds.add(oppty.AccountId);
            }
        }
       
        List<Acc_Yearly_Revenue_Rollup__c> deleteAccYearlyRollups = [Select Id, Name From Acc_Yearly_Revenue_Rollup__c
                                                                     Where Accounts__c != null
                                                                     AND Accounts__c IN : acctIds];
               
        if(deleteAccYearlyRollups.size() >  0 && (Utility.checkObjectPermission(Constants.PERMISSION_DELETE, 'Acc_Yearly_Revenue_Rollup__c')))
            delete deleteAccYearlyRollups;
    }
}