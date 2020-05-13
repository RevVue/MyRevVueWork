/**
*  Description     :   This is the helper class for Monthly Revenue Rollup Trigger.
*
*  Created Date    :   02/07/2020
*
*  Created By      :   Bill Feeheley
*
*  Version         :   V_1.0
**/
public without sharing class MonthlyRevenueRollupTriggerHelper {
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldAccMonthlyResult = Utility.getFieldPermissions('Acc_Monthly_Revenue_Rollup__c');
    
    /**
    *  @description    :   This method is used to calculate monthly rollup on account and handle insert, update and delete case also.    
    *
    *  @args           :   Trigger.New
    *
    *  @return         :   
    **/
    public static void calculateAccMonthlyRollupOnAccount(List<Monthly_Revenue_Rollups__c> newMonthlyRevenueRollup, Map<Id, Monthly_Revenue_Rollups__c> oldMapOfMonthlyRevenueRollup) {
        Set<Id> oppIds = new Set<Id>();
        Id accountId ;
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        Account theAccount = new Account();
        
        for(Monthly_Revenue_Rollups__c newMonthly : newMonthlyRevenueRollup) {
            if((oldMapOfMonthlyRevenueRollup == null 
                || oldMapOfMonthlyRevenueRollup.get(newMonthly.Id).Monthly_Forecasted_Revenue_Weighted__c != newMonthly.Monthly_Forecasted_Revenue_Weighted__c
                || oldMapOfMonthlyRevenueRollup.get(newMonthly.Id).Monthly_Forecasted_Revenue__c != newMonthly.Monthly_Forecasted_Revenue__c
                || oldMapOfMonthlyRevenueRollup.get(newMonthly.Id).Monthly_Actual_Revenue__c != newMonthly.Monthly_Actual_Revenue__c
                || oldMapOfMonthlyRevenueRollup.get(newMonthly.Id).Year__c != newMonthly.Year__c
                || oldMapOfMonthlyRevenueRollup.get(newMonthly.Id).Month__c != newMonthly.Month__c
                || oldMapOfMonthlyRevenueRollup.get(newMonthly.Id).Monthly_Revenue_Date__c != newMonthly.Monthly_Revenue_Date__c
                || oldMapOfMonthlyRevenueRollup.get(newMonthly.Id).Opportunity__c != newMonthly.Opportunity__c)){
                    oppIds.add(newMonthly.Opportunity__c);
                }
        }
        
        if(oppIds.size() > 0 ) { 
            for(Monthly_Revenue_Rollups__c monthly :[Select Id, Name, Opportunity__c, Opportunity__r.AccountId	 
                                                     From Monthly_Revenue_Rollups__c
                                                     Where Opportunity__c IN : oppIds AND Opportunity__r.AccountId != null
                                                     LIMIT 1]) 
            {
                accountId = monthly.Opportunity__r.AccountId;
            }
        }
        
        String queryAcc = '';
        if(accountId != null) {
            if(isMultiCurrencyEnabled)
                queryAcc += 'SELECT Id, name, CurrencyIsoCode FROM Account WHERE Id = \''+ accountId +'\' LIMIT 1 ';
            else
                queryAcc += 'SELECT Id, name FROM Account WHERE Id = \''+ accountId +'\' LIMIT 1 ';
        }
        
        //Database.query for Account
        if(String.isNotEmpty(queryAcc))
            theAccount = Database.query(queryAcc); 
        
        Map<String, Map<String, Id>> mapOfAccIdWithYearWithAccYearlyRollupId = new Map<String, Map<String, Id>>();
        for(Acc_Yearly_Revenue_Rollup__c accYearlyRollup : [Select Id, Name, Year__c, Accounts__c, Yearly_Actual_Revenue__c, Yearly_Forecasted_Revenue__c, Yearly_Forecasted_Revenue_Weighted__c 
                                                            From Acc_Yearly_Revenue_Rollup__c 
                                                            Where Accounts__c =: accountId AND Accounts__c != null]) 
        {
            if(!mapOfAccIdWithYearWithAccYearlyRollupId.containsKey(accYearlyRollup.Accounts__c)) {
                mapOfAccIdWithYearWithAccYearlyRollupId.put(accYearlyRollup.Accounts__c, new Map<String, Id>());
                if(!mapOfAccIdWithYearWithAccYearlyRollupId.get(accYearlyRollup.Accounts__c).containsKey(accYearlyRollup.Accounts__c+'@'+accYearlyRollup.Year__c))
                    mapOfAccIdWithYearWithAccYearlyRollupId.get(accYearlyRollup.Accounts__c).put(accYearlyRollup.Accounts__c+'@'+accYearlyRollup.Year__c, accYearlyRollup.id);
            }
            else{
                mapOfAccIdWithYearWithAccYearlyRollupId.get(accYearlyRollup.Accounts__c).put(accYearlyRollup.Accounts__c+'@'+accYearlyRollup.Year__c, accYearlyRollup.id);
            }
        }
        
        Map<String, Monthly_Revenue_Rollups__c> mapOfYearWithMonthlyRevenueRollups = new Map<String, Monthly_Revenue_Rollups__c>();
        if(accountId != null) {
            for(Yearly_Revenue_Rollups__c yearly :[SELECT id, Name, Opportunity__c, Opportunity__r.AccountId,Year__c,
                                                       (SELECT id, Name, Month__c, Year__c,Monthly_Revenue_Date__c, Opportunity__c, Yearly_Revenue_Rollup__c, 
                                                        Monthly_Actual_Revenue__c, Monthly_Forecasted_Revenue_Weighted__c, Yearly_Revenue_Rollup__r.Name, 
                                                        Monthly_Forecasted_Revenue__c
                                                        FROM Monthly_Revenue_Rollups__r 
                                                        Where Opportunity__r.AccountId =: accountId
                                                        ORDER By Year__c,Month__c ASC)
                                                   FROM Yearly_Revenue_Rollups__c 
                                                   Where Opportunity__r.AccountId =: accountId
                                                   ORDER By Year__c ASC]) 
            {
                for(Monthly_Revenue_Rollups__c monthly : yearly.Monthly_Revenue_Rollups__r)  {
                    String mapKey = accountId + '@' + String.valueOf(yearly.Year__c) + '@' + String.valueOf(monthly.Month__c)+ '@' + String.valueOf(monthly.Year__c);
                    
                    if(mapOfYearWithMonthlyRevenueRollups.containsKey(mapKey)) {
                        Monthly_Revenue_Rollups__c existingYearlyRollup = mapOfYearWithMonthlyRevenueRollups.get(MapKey);
                        
                        existingYearlyRollup.Month__c = monthly.Month__c;
                        existingYearlyRollup.Year__c = monthly.Year__c;
                        existingYearlyRollup.Monthly_Revenue_Date__c = monthly.Monthly_Revenue_Date__c;
                        if(monthly.Monthly_Actual_Revenue__c != null && existingYearlyRollup.Monthly_Actual_Revenue__c != null)
                            existingYearlyRollup.Monthly_Actual_Revenue__c += monthly.Monthly_Actual_Revenue__c;
                        existingYearlyRollup.Monthly_Forecasted_Revenue__c += monthly.Monthly_Forecasted_Revenue__c;
                        existingYearlyRollup.Monthly_Forecasted_Revenue_Weighted__c += monthly.Monthly_Forecasted_Revenue_Weighted__c;
                    } else {
                        mapOfYearWithMonthlyRevenueRollups.put(mapKey, monthly);
                    }
                }
            }
            
        }
        
        Map<String, List<Monthly_Revenue_Rollups__c>> mapOfAccIdWithYearWithMonthlyRollups = new Map<String, List<Monthly_Revenue_Rollups__c>>();
        for(String uniqueAccId : mapOfYearWithMonthlyRevenueRollups.keyset()) {
            if(!mapOfAccIdWithYearWithMonthlyRollups.containsKey(uniqueAccId)) 
                mapOfAccIdWithYearWithMonthlyRollups.put(uniqueAccId, new List<Monthly_Revenue_Rollups__c>());
            mapOfAccIdWithYearWithMonthlyRollups.get(uniqueAccId).add(mapOfYearWithMonthlyRevenueRollups.get(uniqueAccId));
        }
        
        Map<String, List<Acc_Monthly_Revenue_Rollup__c>> mapOfAccIdWithYearWithAccMonthlyRollup = new Map<String, List<Acc_Monthly_Revenue_Rollup__c>>();
        for(Acc_Monthly_Revenue_Rollup__c accMonthlyRollup : [Select Id, Name, Year__c, Month__c, Account__c, Acc_Yearly_Revenue_Rollup__c, Acc_Yearly_Revenue_Rollup__r.Year__c, Monthly_Actual_Revenue__c, Monthly_Forecasted_Revenue__c, Monthly_Forecasted_Revenue_Weighted__c From Acc_Monthly_Revenue_Rollup__c Where Account__c =: accountId]) {
            if(!mapOfAccIdWithYearWithAccMonthlyRollup.containsKey(accMonthlyRollup.Account__c+'@'+accMonthlyRollup.Acc_Yearly_Revenue_Rollup__r.Year__c+'@'+accMonthlyRollup.Month__c +'@'+accMonthlyRollup.Year__c)) 
                mapOfAccIdWithYearWithAccMonthlyRollup.put(accMonthlyRollup.Account__c+'@'+accMonthlyRollup.Acc_Yearly_Revenue_Rollup__r.Year__c+'@'+accMonthlyRollup.Month__c +'@'+accMonthlyRollup.Year__c, new List<Acc_Monthly_Revenue_Rollup__c>());
            mapOfAccIdWithYearWithAccMonthlyRollup.get(accMonthlyRollup.Account__c+'@'+accMonthlyRollup.Acc_Yearly_Revenue_Rollup__r.Year__c+'@'+accMonthlyRollup.Month__c +'@'+accMonthlyRollup.Year__c).add(accMonthlyRollup);
        }
        
        List<Acc_Monthly_Revenue_Rollup__c> accMonthlyRollupToBeUpdate = new List<Acc_Monthly_Revenue_Rollup__c>();
        List<Acc_Monthly_Revenue_Rollup__c> listOfAccMonthlyIDs = new List<Acc_Monthly_Revenue_Rollup__c>();
        if(mapOfAccIdWithYearWithAccMonthlyRollup.size() > 0) {
            for(String mapkey : mapOfAccIdWithYearWithAccMonthlyRollup.Keyset()) {
                listOfAccMonthlyIDs.addAll(mapOfAccIdWithYearWithAccMonthlyRollup.get(mapkey));
            } 
        }
        for(String uniqueAccId : mapOfAccIdWithYearWithMonthlyRollups.Keyset()) {
            List<String> splitteduniqueKey = uniqueAccId.split('@');
            for(Monthly_Revenue_Rollups__c monthly : mapOfAccIdWithYearWithMonthlyRollups.get(uniqueAccId)) {
                if(listOfAccMonthlyIDs.size() > 0) {
                    Acc_Monthly_Revenue_Rollup__c accMonthlyRollup = new Acc_Monthly_Revenue_Rollup__c(Id = listOfAccMonthlyIDs[0].Id,
                                                                                                       Monthly_Actual_Revenue__c = null,
                                                                                                       Monthly_Forecasted_Revenue__c = 0,
                                                                                                       Monthly_Forecasted_Revenue_Weighted__c = 0
                                                                                                      );
                    
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Name',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Name = monthly.Name;
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Account__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Account__c = uniqueAccId.split('@')[0];
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Month__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Month__c = monthly.Month__c;
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Year__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Year__c = monthly.Year__c;
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Monthly_Revenue_Date__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Monthly_Revenue_Date__c = monthly.Monthly_Revenue_Date__c;
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Acc_Yearly_Revenue_Rollup__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Acc_Yearly_Revenue_Rollup__c = mapOfAccIdWithYearWithAccYearlyRollupId.get(uniqueAccId.split('@')[0]).get(splitteduniqueKey[0]+'@'+ splitteduniqueKey[1]);
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Monthly_Actual_Revenue__c',Constants.PERMISSION_UPSERT)){
                        if(monthly.Monthly_Actual_Revenue__c != null)
                            accMonthlyRollup.Monthly_Actual_Revenue__c = monthly.Monthly_Actual_Revenue__c;
                    }
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Monthly_Forecasted_Revenue__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Monthly_Forecasted_Revenue__c = monthly.Monthly_Forecasted_Revenue__c;
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Monthly_Forecasted_Revenue_Weighted__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Monthly_Forecasted_Revenue_Weighted__c = monthly.Monthly_Forecasted_Revenue_Weighted__c;
                    if(isMultiCurrencyEnabled)
                        accMonthlyRollup.put('CurrencyIsoCode', theAccount.get('CurrencyIsoCode'));
                    
                    if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'Acc_Monthly_Revenue_Rollup__c'))
                        accMonthlyRollupToBeUpdate.add(accMonthlyRollup);
                    listOfAccMonthlyIDs.remove(0);
                    
                } else {
                    Acc_Monthly_Revenue_Rollup__c accMonthlyRollup = new Acc_Monthly_Revenue_Rollup__c();
                    
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Name',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Name = monthly.Name;
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Account__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Account__c = uniqueAccId.split('@')[0];
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Year__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Year__c = monthly.Year__c;
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Month__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Month__c = monthly.Month__c;
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Monthly_Revenue_Date__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Monthly_Revenue_Date__c = monthly.Monthly_Revenue_Date__c;
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Acc_Yearly_Revenue_Rollup__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Acc_Yearly_Revenue_Rollup__c = mapOfAccIdWithYearWithAccYearlyRollupId.get(uniqueAccId.split('@')[0]).get(splitteduniqueKey[0]+'@'+ splitteduniqueKey[1]);
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Monthly_Actual_Revenue__c',Constants.PERMISSION_UPSERT)){
                        if(monthly.Monthly_Actual_Revenue__c != null)
                            accMonthlyRollup.Monthly_Actual_Revenue__c = monthly.Monthly_Actual_Revenue__c;
                    }
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Monthly_Forecasted_Revenue__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Monthly_Forecasted_Revenue__c = monthly.Monthly_Forecasted_Revenue__c;
                    if(Utility.checkFieldPermission(mapfieldAccMonthlyResult,'Monthly_Forecasted_Revenue_Weighted__c',Constants.PERMISSION_UPSERT))
                        accMonthlyRollup.Monthly_Forecasted_Revenue_Weighted__c = monthly.Monthly_Forecasted_Revenue_Weighted__c;
                    if(isMultiCurrencyEnabled)
                        accMonthlyRollup.put('CurrencyIsoCode', theAccount.get('CurrencyIsoCode'));
                    if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'Acc_Monthly_Revenue_Rollup__c'))
                        accMonthlyRollupToBeUpdate.add(accMonthlyRollup);
                }
            }
        }
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'Acc_Monthly_Revenue_Rollup__c')){
            if(accMonthlyRollupToBeUpdate.size() > 0)
            upsert accMonthlyRollupToBeUpdate;
    }
} 
    
    /**
    *  @description    :   This method is used to delete monthly rollup on account    
    *
    *  @args           :   Trigger.oldMap
    *
    *  @return         :   
    **/
    public static void deleteAccMonthlyRollups(Map<Id, Monthly_Revenue_Rollups__c> oldMapOfMonthlyRevenueRollup) {
        Set<Id> opptIds = new Set<Id>();
        Set<Id> acctIds = new Set<Id>();
        
        if(oldMapOfMonthlyRevenueRollup != null) {
            for(Id monthlyId : oldMapOfMonthlyRevenueRollup.keyset()){
                opptIds.add(oldMapOfMonthlyRevenueRollup.get(monthlyId).Opportunity__c);
            }
        }
        if(opptIds.size() > 0 ) { 
            for(Opportunity oppty :[Select Id, Name, AccountId From Opportunity Where Id IN : opptIds]) 
            {
                acctIds.add(oppty.AccountId);
            }
        }
        List<Acc_Monthly_Revenue_Rollup__c> deleteAccMonthlyRollups = [Select Id, Name From Acc_Monthly_Revenue_Rollup__c
                                                                       Where Account__c != null
                                                                       AND Account__c IN : acctIds];
       
        if(deleteAccMonthlyRollups.size() > 0 && (Utility.checkObjectPermission(Constants.PERMISSION_DELETE, 'Acc_Monthly_Revenue_Rollup__c')))
            delete deleteAccMonthlyRollups;
    }
}